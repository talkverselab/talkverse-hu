import 'dart:convert';
import 'dart:math';

import '../core/prefs.dart';
import 'dialogue_service.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`, uk 11-22 — 사용자 지시
/// 「레벨에서 다이얼로그를 고르고 연습·복습해서 80% 이상이면 코스가 넘어가고 매일 분량을 주고」).
/// 저장 키 `curriculum_v1`(전 언어 같은 이름, 형식은 문서 §7) — 기기 저장, 서버 동기화는 나중에 uk.
const kCurriculumKey = 'curriculum_v1';
const kPassPercent = 80;
const kReviewSteps = [1, 3, 7]; // 일 — 맞히면 다음 간격, 틀리면 1일로
const kCourseSizes = [3, 5, 10];
const kDailyGoals = {'light': 1, 'normal': 2, 'focus': 3}; // 새 편 수

/// 점수 = 정답 수 / 문제 수 ×100, 소수점 버림(§5).
int scorePercent(int right, int total) => total <= 0 ? 0 : (right * 100) ~/ total;
bool isPass(int right, int total) => scorePercent(right, total) >= kPassPercent;

/// 날짜 → `2026-11-22`(기기 시각 기준 하루).
String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ReviewItem {
  final String lineId; // `<편 id>#<줄 번호>`
  String due; // dayKey
  int step; // kReviewSteps 의 자리(0 = 1일)
  ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map j) => ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

/// 간격 반복 다음 자리: 맞히면 다음 간격(마지막 간격에 머묾), 틀리면 1일로(§4).
(int step, String due) nextReview({required int step, required bool correct, required DateTime today}) {
  final s = correct ? min(step + 1, kReviewSteps.length - 1) : 0;
  final gap = correct ? kReviewSteps[s] : kReviewSteps[0];
  return (s, dayKey(DateTime(today.year, today.month, today.day + gap)));
}

class Course {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  String? passedAt;
  Course({required this.id, required this.dialogueIds, List<String>? practiced, List<int>? examScores, this.passedAt})
      : practiced = practiced ?? [],
        examScores = examScores ?? [];
  bool get allPracticed => dialogueIds.every(practiced.contains);
  Map<String, dynamic> toJson() => {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory Course.fromJson(Map j) => Course(
        id: '${j['id']}',
        dialogueIds: [for (final e in (j['dialogueIds'] as List? ?? const [])) '$e'],
        practiced: [for (final e in (j['practiced'] as List? ?? const [])) '$e'],
        examScores: [for (final e in (j['examScores'] as List? ?? const [])) (e as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

class CurriculumState {
  String? level;
  String dailyGoal;
  Course? course;
  final List<String> passedDialogues;
  final List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  // 오늘 한 것(문서 §7 형식 밖의 덧붙임 — 하루 분량 표시용)
  String? todayDay;
  final List<String> todayNew;
  int todayReviewed;

  CurriculumState({
    this.level,
    this.dailyGoal = 'normal',
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay,
    List<String>? todayNew,
    this.todayReviewed = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [],
        todayNew = todayNew ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'new': todayNew, 'reviewed': todayReviewed},
      };

  factory CurriculumState.fromJson(Map j) {
    final st = (j['streak'] as Map?) ?? const {};
    final td = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: kDailyGoals.containsKey(j['dailyGoal']) ? j['dailyGoal'] as String : 'normal',
      course: j['course'] is Map ? Course.fromJson(j['course'] as Map) : null,
      passedDialogues: [for (final e in (j['passedDialogues'] as List? ?? const [])) '$e'],
      review: [for (final e in (j['review'] as List? ?? const [])) if (e is Map) ReviewItem.fromJson(e)],
      streakCount: (st['count'] as num?)?.toInt() ?? 0,
      streakLastDay: st['lastDay'] as String?,
      todayDay: td['day'] as String?,
      todayNew: [for (final e in (td['new'] as List? ?? const [])) '$e'],
      todayReviewed: (td['reviewed'] as num?)?.toInt() ?? 0,
    );
  }

  int get newGoal => kDailyGoals[dailyGoal] ?? 2;

  /// 날짜가 바뀌었으면 오늘 칸을 비운다.
  void rollDay(DateTime now) {
    final k = dayKey(now);
    if (todayDay != k) {
      todayDay = k;
      todayNew.clear();
      todayReviewed = 0;
    }
  }

  List<ReviewItem> dueReviews(DateTime now) {
    final k = dayKey(now);
    return review.where((r) => r.due.compareTo(k) <= 0).toList();
  }

  int newLeftToday(DateTime now) {
    rollDay(now);
    return max(0, newGoal - todayNew.length);
  }

  bool doneToday(DateTime now) => dueReviews(now).isEmpty && newLeftToday(now) == 0;

  /// 오늘 분량을 다 했으면 연속 일수를 올린다(하루 한 번).
  void touchStreak(DateTime now) {
    if (!doneToday(now)) return;
    final k = dayKey(now);
    if (streakLastDay == k) return;
    final y = dayKey(DateTime(now.year, now.month, now.day - 1));
    streakCount = streakLastDay == y ? streakCount + 1 : 1;
    streakLastDay = k;
  }

  /// 줄을 복습 대기열에 넣는다(이미 있으면 틀렸을 때만 1일로 되돌림).
  void enqueue(String lineId, {required bool wrong, required DateTime now}) {
    final cur = review.where((r) => r.lineId == lineId).firstOrNull;
    if (cur == null) {
      review.add(ReviewItem(lineId, dayKey(DateTime(now.year, now.month, now.day + kReviewSteps[0])), 0));
    } else if (wrong) {
      cur
        ..step = 0
        ..due = dayKey(DateTime(now.year, now.month, now.day + kReviewSteps[0]));
    }
  }

  void answerReview(String lineId, {required bool correct, required DateTime now}) {
    final cur = review.where((r) => r.lineId == lineId).firstOrNull;
    if (cur == null) return;
    final (s, d) = nextReview(step: cur.step, correct: correct, today: now);
    cur
      ..step = s
      ..due = d;
    rollDay(now);
    todayReviewed++;
  }

  void markPracticed(String dialogueId, DateTime now) {
    final c = course;
    if (c == null) return;
    rollDay(now);
    if (!c.practiced.contains(dialogueId)) {
      c.practiced.add(dialogueId);
      if (!todayNew.contains(dialogueId)) todayNew.add(dialogueId);
    }
  }

  /// 시험 결과 기록. 통과면 코스 완료 + 편 통과 표시. 돌려주는 값 = 통과 여부.
  bool recordExam(int right, int total, DateTime now, {List<String> failedDialogues = const []}) {
    final c = course;
    if (c == null) return false;
    c.examScores.add(scorePercent(right, total));
    if (isPass(right, total)) {
      c.passedAt = dayKey(now);
      for (final id in c.dialogueIds) {
        if (!passedDialogues.contains(id)) passedDialogues.add(id);
      }
      return true;
    }
    // 80% 미만 — 틀린 편만 다시 연습(§5)
    c.practiced.removeWhere(failedDialogues.contains);
    return false;
  }
}

/// 「추천으로 채우기」: 아직 통과·선택 안 한 편에서 주제가 겹치지 않게 차례로 고른다(§2).
List<String> recommend(List<Dialogue> levelDialogues, {required Set<String> passed, required Set<String> chosen, required int size}) {
  final out = [...chosen];
  final pool = levelDialogues.where((d) => !passed.contains(d.id) && !chosen.contains(d.id)).toList();
  final usedTopics = {for (final d in levelDialogues) if (chosen.contains(d.id)) d.topic};
  while (out.length < size && pool.isNotEmpty) {
    final pick = pool.firstWhere((d) => !usedTopics.contains(d.topic), orElse: () {
      usedTopics.clear(); // 주제를 한 바퀴 다 썼으면 다시
      return pool.first;
    });
    out.add(pick.id);
    usedTopics.add(pick.topic);
    pool.remove(pick);
  }
  // 남은 편이 모자라면 통과한 편으로 채우지 않는다(다시 고르기는 학습자가 직접)
  return out;
}

/// 레벨의 편을 모두 통과했는가.
bool levelCleared(List<Dialogue> levelDialogues, Set<String> passed) =>
    levelDialogues.isNotEmpty && levelDialogues.every((d) => passed.contains(d.id));

class CurriculumStore {
  CurriculumStore._();
  static Future<CurriculumState> load() async {
    final p = await Prefs.getInstance();
    final raw = p.getString(kCurriculumKey);
    if (raw == null || raw.isEmpty) return CurriculumState();
    try {
      return CurriculumState.fromJson(json.decode(raw) as Map);
    } catch (_) {
      return CurriculumState();
    }
  }

  static Future<void> save(CurriculumState s) async {
    final p = await Prefs.getInstance();
    await p.setString(kCurriculumKey, json.encode(s.toJson()));
  }
}

/// 확인 문제 한 개 — 그 줄의 헝가리어를 보고 뜻 4지선다(앱에 이미 있는 꼴, §3).
class CurQ {
  final String lineId;
  final String dialogueId;
  final String stem; // 헝가리어
  final String answer; // 한국어 뜻
  final List<String> options;
  const CurQ(this.lineId, this.dialogueId, this.stem, this.answer, this.options);
}

String lineIdOf(Dialogue d, DialogueTurn t) => '${d.id}#${t.num}';

CurQ? makeQ(Dialogue d, DialogueTurn t, List<String> koPool, Random rnd) {
  if (t.tl.trim().isEmpty || t.ko.trim().isEmpty) return null;
  final others = ({for (final k in koPool) if (k != t.ko && k.trim().isNotEmpty) k}.toList()..shuffle(rnd)).take(3).toList();
  if (others.length < 3) return null;
  return CurQ(lineIdOf(d, t), d.id, t.tl, t.ko, [t.ko, ...others]..shuffle(rnd));
}

/// 편 연습 문제: 줄 수만큼, 최대 10(§3). 오답 보기는 같은 레벨의 다른 줄 뜻.
List<CurQ> practiceQuestions(Dialogue d, List<String> koPool, Random rnd, {int maxN = 10}) {
  final turns = [...d.turns]..shuffle(rnd);
  return [for (final t in turns) ?makeQ(d, t, koPool, rnd)].take(maxN).toList();
}

/// 코스 시험: 편당 최소 3, 전체 최대 30(§5).
List<CurQ> examQuestions(List<Dialogue> ds, List<String> koPool, Random rnd) {
  if (ds.isEmpty) return const [];
  final per = max(3, min(10, 30 ~/ ds.length));
  final out = <CurQ>[];
  for (final d in ds) {
    out.addAll(practiceQuestions(d, koPool, rnd, maxN: per));
  }
  out.shuffle(rnd);
  return out.take(30).toList();
}
