import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 무료/유료 구분 — Talkverse 계정 이용권(lang 'hu', auth.talkverse.uk) OR 이 기기에서 산·복원한 평생 이용권(스토어).
/// 2026-11-02: 아직 잠그는 기능은 없다(모든 기능 무료). 유료 범위가 정해지면 화면에서 [premium] 을 보고 [showPaywall] 을 띄운다.
class Entitlement {
  Entitlement._();
  static const lang = 'hu';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
