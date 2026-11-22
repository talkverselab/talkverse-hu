import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';

/// 토크버스 커리큘럼 — 레벨 고르기 → 다이얼로그 고르기(3·5·10) → 편마다 듣기·확인 문제 → 코스 시험(80% 통과) · 간격 반복 복습 · 하루 분량.
/// 전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`(uk 11-22). 기존 화면은 건드리지 않는 새 메뉴.
class CurriculumScreen extends StatefulWidget {
  final DateTime Function()? clock; // 시험용
  const CurriculumScreen({super.key, this.clock});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  CurriculumState? _s;
  bool _pickLevel = false;
  int _size = 5;
  final Set<String> _chosen = {};
  bool _askDiscard = false;
  final _rnd = Random();

  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  DialogueService get _svc => DialogueService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _svc.ensureLoaded();
    final s = await CurriculumStore.load();
    s.rollDay(_now);
    if (s.level != null && !_svc.regions.contains(s.level)) s.level = null;
    if (mounted) {
      setState(() {
        _s = s;
        _pickLevel = s.level == null;
      });
    }
  }

  Future<void> _save() async {
    final s = _s!;
    s.touchStreak(_now);
    await CurriculumStore.save(s);
    if (mounted) setState(() {});
  }

  List<String> get _levels => _svc.regions.where((r) => r.startsWith('R')).toList();
  List<Dialogue> _levelDs(String lv) => _svc.list(region: lv);
  List<String> _koPool(String lv) => [for (final d in _levelDs(lv)) for (final t in d.turns) t.ko];

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('토크버스 커리큘럼'))),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : _pickLevel
              ? _levelPicker(s)
              : _courseView(s),
    );
  }

  // ── 레벨 고르기 ──
  Widget _levelPicker(CurriculumState s) {
    final levels = _levels;
    final passed = s.passedDialogues.toSet();
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)),
      children: [
        Text(tr('회화 레벨을 고르세요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
        const SizedBox(height: 4),
        Text(tr('처음이라면 가장 낮은 레벨부터 권해요.'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
        const SizedBox(height: 14),
        for (final (i, lv) in levels.indexed)
          Card(
            elevation: 0,
            color: AppColors.washiDeep,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.line)),
            child: ListTile(
              key: ValueKey('cur-level-$lv'),
              title: Text('$lv · ${tr(DialogueService.levelKo[lv] ?? lv)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(trf('{0}편 중 {1}편 통과', [_levelDs(lv).length, _levelDs(lv).where((d) => passed.contains(d.id)).length])),
              trailing: i == 0 && s.level == null
                  ? Text(tr('추천'), style: const TextStyle(color: AppColors.beni, fontWeight: FontWeight.w800))
                  : (levelCleared(_levelDs(lv), passed) ? const Icon(Icons.check_circle, color: AppColors.matcha) : null),
              onTap: () async {
                if (s.level != lv) {
                  s.level = lv;
                  if (s.course != null && s.course!.passedAt == null && !_levelDs(lv).any((d) => s.course!.dialogueIds.contains(d.id))) {
                    // 다른 레벨의 진행 중 코스는 그대로 두면 섞이므로 비운다(레벨을 바꾸는 것은 학습자 선택)
                    s.course = null;
                  }
                  _chosen.clear();
                }
                await _save();
                setState(() => _pickLevel = false);
              },
            ),
          ),
      ],
    );
  }

  // ── 코스 화면 ──
  Widget _courseView(CurriculumState s) {
    final lv = s.level!;
    final c = s.course;
    final active = c != null && c.passedAt == null;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        Row(children: [
          Expanded(child: Text('$lv · ${tr(DialogueService.levelKo[lv] ?? lv)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.sumi))),
          TextButton(key: const ValueKey('cur-change-level'), onPressed: () => setState(() => _pickLevel = true), child: Text(tr('레벨 바꾸기'))),
        ]),
        const SizedBox(height: 6),
        _todayCard(s),
        const SizedBox(height: 14),
        if (levelCleared(_levelDs(lv), s.passedDialogues.toSet())) _clearedBanner(s, lv),
        if (active && !_askDiscard) _activeCourse(s, c) else if (_askDiscard) _discardPanel(s) else _builder(s, lv),
      ],
    );
  }

  Widget _todayCard(CurriculumState s) {
    final now = _now;
    final due = s.dueReviews(now).length;
    final newLeft = s.newLeftToday(now);
    final goalTotal = s.newGoal + s.todayReviewed + due;
    final doneCount = s.todayNew.length.clamp(0, s.newGoal) + s.todayReviewed;
    final ratio = goalTotal == 0 ? 1.0 : (doneCount / goalTotal).clamp(0.0, 1.0);
    final done = s.doneToday(now);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              done ? tr('오늘 분량 끝') : trf('오늘: 복습 {0} · 새 편 {1}', [due, newLeft]),
              key: const ValueKey('cur-today'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: done ? AppColors.matcha : AppColors.sumi),
            ),
          ),
          if (s.streakCount > 0) Text(trf('🔥 {0}일 연속', [s.streakCount]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.beni)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: AppColors.line, color: AppColors.matcha),
        ),
        const SizedBox(height: 10),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 4, children: [
          Text(tr('하루 목표'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
          const SizedBox(width: 8),
          for (final (k, label) in [('light', tr('가볍게')), ('normal', tr('보통')), ('focus', tr('집중'))])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: ValueKey('cur-goal-$k'),
                label: Text(label),
                selected: s.dailyGoal == k,
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  s.dailyGoal = k;
                  _save();
                },
              ),
            ),
        ]),
        if (due > 0) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('cur-review'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.beni),
            onPressed: () => _startReview(s),
            icon: const Icon(Icons.replay, size: 18),
            label: Text(trf('복습 {0}줄 시작', [due])),
          ),
        ],
      ]),
    );
  }

  Widget _clearedBanner(CurriculumState s, String lv) {
    final i = _levels.indexOf(lv);
    final next = i >= 0 && i + 1 < _levels.length ? _levels[i + 1] : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0x1A0E6245), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Text(next == null ? tr('이 레벨의 회화를 모두 통과했어요.') : trf('이 레벨 통과! {0} 레벨이 열렸어요.', [next]), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.matcha))),
        if (next != null)
          TextButton(
            onPressed: () async {
              s.level = next;
              _chosen.clear();
              await _save();
            },
            child: Text(trf('{0}로', [next])),
          ),
      ]),
    );
  }

  Widget _activeCourse(CurriculumState s, Course c) {
    final ds = [for (final id in c.dialogueIds) ?_svc.byId(id)];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(trf('지금 코스 · {0}편', [ds.length]), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
      if (c.examScores.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(trf('지난 시험: {0}% — 80% 이상이면 통과', [c.examScores.last]), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        ),
      const SizedBox(height: 8),
      for (final d in ds)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.line)),
          child: ListTile(
            key: ValueKey('cur-dlg-${d.id}'),
            leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(c.practiced.contains(d.id) ? tr('연습 끝') : tr('연습하기 — 듣기 · 확인 문제')),
            trailing: c.practiced.contains(d.id) ? const Icon(Icons.check_circle, color: AppColors.matcha) : const Icon(Icons.chevron_right),
            onTap: () => _practice(s, d),
          ),
        ),
      const SizedBox(height: 10),
      FilledButton(
        key: const ValueKey('cur-exam'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
        onPressed: c.allPracticed ? () => _exam(s, ds) : null,
        child: Text(c.allPracticed ? tr('코스 시험 보기') : tr('모든 편을 연습하면 시험이 열려요')),
      ),
      const SizedBox(height: 6),
      TextButton(onPressed: () => setState(() => _askDiscard = true), child: Text(tr('새 코스 만들기'))),
    ]);
  }

  Widget _discardPanel(CurriculumState s) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0x14D83A3A), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('지금 코스를 그만두고 새 코스를 만들까요?'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(height: 4),
          Text(tr('연습한 기록은 복습에 남고, 코스 진행만 지워져요.'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(key: const ValueKey('cur-keep'), onPressed: () => setState(() => _askDiscard = false), child: Text(tr('계속하기')))),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const ValueKey('cur-discard'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD83A3A)),
                onPressed: () async {
                  s.course = null;
                  _chosen.clear();
                  _askDiscard = false;
                  await _save();
                },
                child: Text(tr('새로 만들기')),
              ),
            ),
          ]),
        ]),
      );

  Widget _builder(CurriculumState s, String lv) {
    final ds = _levelDs(lv);
    final passed = s.passedDialogues.toSet();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(tr('다이얼로그를 골라 코스를 만드세요'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
      const SizedBox(height: 8),
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 4, children: [
        Text(tr('개수'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        const SizedBox(width: 8),
        for (final n in kCourseSizes)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              key: ValueKey('cur-size-$n'),
              label: Text(trf('{0}편', [n])),
              selected: _size == n,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() {
                _size = n;
                while (_chosen.length > n) {
                  _chosen.remove(_chosen.last);
                }
              }),
            ),
          ),
        TextButton(
          key: const ValueKey('cur-recommend'),
          onPressed: () => setState(() {
            final r = recommend(ds, passed: passed, chosen: _chosen, size: _size);
            _chosen
              ..clear()
              ..addAll(r);
          }),
          child: Text(tr('추천으로 채우기')),
        ),
      ]),
      FilledButton(
        key: const ValueKey('cur-start'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.beni, minimumSize: const Size.fromHeight(46)),
        onPressed: _chosen.length == _size
            ? () async {
                s.course = Course(id: 'c${_now.millisecondsSinceEpoch}', dialogueIds: [..._chosen]);
                _chosen.clear();
                await _save();
              }
            : null,
        child: Text(trf('코스 시작 ({0}/{1})', [_chosen.length, _size])),
      ),
      const SizedBox(height: 8),
      for (final d in ds)
        CheckboxListTile(
          key: ValueKey('cur-pick-${d.id}'),
          dense: true,
          value: _chosen.contains(d.id),
          onChanged: (v) => setState(() {
            if (v == true) {
              if (_chosen.length < _size) _chosen.add(d.id);
            } else {
              _chosen.remove(d.id);
            }
          }),
          secondary: Text(d.emoji, style: const TextStyle(fontSize: 20)),
          title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${tr(DialogueService.topicKo[d.topic] ?? d.topic)}${passed.contains(d.id) ? ' · ${tr('통과')} ✓' : ''}'),
        ),
    ]);
  }

  // ── 연습 · 시험 · 복습 ──
  Future<void> _practice(CurriculumState s, Dialogue d) async {
    final res = await Navigator.of(context).push<List<(CurQ, bool)>>(MaterialPageRoute(
      builder: (_) => CurPracticeScreen(dialogue: d, questions: practiceQuestions(d, _koPool(s.level!), _rnd)),
    ));
    if (res == null) return;
    final now = _now;
    for (final t in d.turns) {
      s.enqueue(lineIdOf(d, t), wrong: false, now: now);
    }
    for (final (q, ok) in res) {
      if (!ok) s.enqueue(q.lineId, wrong: true, now: now);
    }
    s.markPracticed(d.id, now);
    await _save();
  }

  Future<void> _exam(CurriculumState s, List<Dialogue> ds) async {
    final qs = examQuestions(ds, _koPool(s.level!), _rnd);
    final res = await Navigator.of(context).push<List<(CurQ, bool)>>(MaterialPageRoute(
      builder: (_) => CurQuizScreen(title: tr('코스 시험'), questions: qs, showPass: true),
    ));
    if (res == null) return;
    final now = _now;
    final right = res.where((e) => e.$2).length;
    final failed = {for (final (q, ok) in res) if (!ok) q.dialogueId};
    for (final (q, ok) in res) {
      if (!ok) s.enqueue(q.lineId, wrong: true, now: now);
    }
    s.recordExam(right, res.length, now, failedDialogues: failed.toList());
    await _save();
  }

  Future<void> _startReview(CurriculumState s) async {
    final now = _now;
    final due = s.dueReviews(now);
    final pool = [for (final d in _svc.all) for (final t in d.turns) t.ko];
    final qs = <CurQ>[];
    for (final r in due) {
      final parts = r.lineId.split('#');
      final d = _svc.byId(parts.first);
      final t = d?.turns.where((t) => '${t.num}' == parts.last).firstOrNull;
      final q = d == null || t == null ? null : makeQ(d, t, pool, _rnd);
      if (q == null) {
        s.review.remove(r); // 원고에서 사라진 줄
      } else {
        qs.add(q);
      }
    }
    if (qs.isEmpty) {
      await _save();
      return;
    }
    final res = await Navigator.of(context).push<List<(CurQ, bool)>>(MaterialPageRoute(
      builder: (_) => CurQuizScreen(title: tr('오늘 복습'), questions: qs..shuffle(_rnd)),
    ));
    if (res == null) return;
    for (final (q, ok) in res) {
      s.answerReview(q.lineId, correct: ok, now: _now);
    }
    await _save();
  }
}

/// 편 연습: ① 듣기·읽기(줄마다 뜻 보기, 탭하면 그 줄 듣기 = 따라 말하기) → ② 확인 문제.
class CurPracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  final List<CurQ> questions;
  const CurPracticeScreen({super.key, required this.dialogue, required this.questions});
  @override
  State<CurPracticeScreen> createState() => _CurPracticeScreenState();
}

class _CurPracticeScreenState extends State<CurPracticeScreen> {
  bool _showKo = true;
  int? _playing;
  bool _stop = false;

  Dialogue get d => widget.dialogue;

  Future<void> _say(DialogueTurn t) => TtsService.instance.speakAs(t.tl, gender: d.voiceGender(t.speaker));

  Future<void> _playAll() async {
    _stop = false;
    for (var i = 0; i < d.turns.length && !_stop && mounted; i++) {
      setState(() => _playing = i);
      final t = d.turns[i];
      await _say(t);
      // 기기 TTS 는 끝날 때를 기다려 주지 않아 글자 수로 어림잡는다
      await Future.delayed(Duration(milliseconds: 900 + t.tl.length * 75));
    }
    if (mounted) setState(() => _playing = null);
  }

  @override
  void dispose() {
    _stop = true;
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(d.title), actions: [
        IconButton(
          tooltip: tr('뜻 보기'),
          icon: Icon(_showKo ? Icons.translate : Icons.translate_outlined, color: _showKo ? AppColors.ai : null),
          onPressed: () => setState(() => _showKo = !_showKo),
        ),
      ]),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              if (d.sceneShown.isNotEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(d.sceneShown, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight))),
              Text(tr('① 듣고 읽기 — 줄을 누르면 그 줄만 다시 들어요(따라 말해 보세요)'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
              const SizedBox(height: 8),
              for (final (i, t) in d.turns.indexed)
                InkWell(
                  onTap: () => _say(t),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _playing == i ? const Color(0x1A635BFF) : AppColors.washiDeep,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.speakerName(t.speaker), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.beni)),
                      Text(t.tl, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                      if (_showKo) Text(t.ko, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _playing == null ? _playAll : () => setState(() => _stop = true),
                icon: Icon(_playing == null ? Icons.play_arrow : Icons.stop),
                label: Text(_playing == null ? tr('전체 듣기') : tr('멈춤')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const ValueKey('cur-to-quiz'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.sumi),
                onPressed: () async {
                  _stop = true;
                  final nav = Navigator.of(context);
                  final res = await nav.push<List<(CurQ, bool)>>(MaterialPageRoute(
                    builder: (_) => CurQuizScreen(title: tr('② 확인 문제'), questions: widget.questions),
                  ));
                  if (res != null) nav.pop(res);
                },
                child: Text(trf('② 확인 문제 {0}개', [widget.questions.length])),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// 뜻 고르기 4지선다 — 끝나면 [(문제, 맞음)] 을 돌려준다.
class CurQuizScreen extends StatefulWidget {
  final String title;
  final List<CurQ> questions;
  final bool showPass;
  const CurQuizScreen({super.key, required this.title, required this.questions, this.showPass = false});
  @override
  State<CurQuizScreen> createState() => _CurQuizScreenState();
}

class _CurQuizScreenState extends State<CurQuizScreen> {
  int _i = 0;
  String? _picked;
  final List<(CurQ, bool)> _res = [];

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(widget.title)),
      body: qs.isEmpty || _i >= qs.length ? _summary() : _question(qs[_i], qs.length),
    );
  }

  Widget _summary() {
    final n = _res.length;
    final right = _res.where((e) => e.$2).length;
    final pct = scorePercent(right, n);
    final pass = isPass(right, n);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.showPass ? (pass ? '🎉' : '💪') : '✅', style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(trf('{0}문제 중 {1}개 맞힘 · {2}%', [n, right, pct]), key: const ValueKey('cur-score'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          if (widget.showPass) ...[
            const SizedBox(height: 6),
            Text(pass ? tr('통과! 코스를 마쳤어요.') : tr('80% 미만 — 틀린 편만 다시 연습하고 다시 시험을 봐요.'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: pass ? AppColors.matcha : AppColors.sumiLight, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('cur-done'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi),
            onPressed: () => Navigator.of(context).pop(_res),
            child: Text(tr('확인')),
          ),
        ]),
      ),
    );
  }

  Widget _question(CurQ q, int n) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${tr('뜻')} · ${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text(q.stem, key: const ValueKey('cur-stem'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.sumi))),
          IconButton(icon: const Icon(Icons.volume_up), onPressed: () => TtsService.instance.speak(q.stem)),
        ]),
        const SizedBox(height: 8),
        Text(tr('뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 14, color: AppColors.sumi)),
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('cur-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _picked == null ? null : (q.options[k] == q.answer ? const Color(0x3336A35B) : (q.options[k] == _picked ? const Color(0x33D83A3A) : null)),
                side: BorderSide(color: _picked != null && q.options[k] == q.answer ? AppColors.matcha : AppColors.line, width: 1.4),
              ),
              onPressed: _picked != null
                  ? null
                  : () {
                      final ok = q.options[k] == q.answer;
                      unawaited(TtsService.instance.speak(q.stem));
                      setState(() {
                        _picked = q.options[k];
                        _res.add((q, ok));
                      });
                    },
              child: Text(q.options[k], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
            ),
          ),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('cur-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}
