// Guards the application identity: the Android applicationId / namespace /
// Kotlin package, the iOS & macOS bundle ids, the Linux application id and the
// Windows company name must all agree on one reverse-domain prefix, and none of
// them may fall back to the `com.example` placeholder.
//
// These ids are what you register in Google Cloud Console (and the app stores),
// so a drift here silently breaks Google Sign-In with a
// `clientConfigurationError`. See docs/google_signin.md.
//
// Run with:
//   flutter test test/app_identity_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Parses capture group 1, throwing a clear error when the pattern is absent.
String _capture(String source, RegExp re, String what) {
  final match = re.firstMatch(source);
  if (match == null) {
    throw StateError('could not find $what (pattern: ${re.pattern})');
  }
  return match.group(1)!.trim();
}

void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final kotlinCandidates = Directory('android/app/src/main/kotlin')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('MainActivity.kt'))
      .toList();
  final iosPbx =
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
  final macosCfg =
      File('macos/Runner/Configs/AppInfo.xcconfig').readAsStringSync();
  final macosPbx =
      File('macos/Runner.xcodeproj/project.pbxproj').readAsStringSync();
  final linux = File('linux/CMakeLists.txt').readAsStringSync();
  final windowsRc = File('windows/runner/Runner.rc').readAsStringSync();

  final androidId = _capture(
      gradle, RegExp(r'applicationId\s*=\s*"([^"]+)"'), 'applicationId');
  final androidNs =
      _capture(gradle, RegExp(r'namespace\s*=\s*"([^"]+)"'), 'namespace');
  final kotlinPkg = kotlinCandidates.isEmpty
      ? ''
      : _capture(
          kotlinCandidates.first.readAsStringSync(),
          RegExp(r'^package\s+(\S+)', multiLine: true),
          'Kotlin package declaration',
        );

  final iosIds = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);')
      .allMatches(iosPbx)
      .map((m) => m.group(1)!.trim())
      .toSet();
  final macosIds = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^\s;]+)')
      .allMatches(macosPbx)
      .map((m) => m.group(1)!.trim())
      .toSet();
  final macosAppId = _capture(macosCfg,
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(\S+)'), 'macOS bundle id');
  final linuxId = _capture(
      linux, RegExp(r'set\(APPLICATION_ID\s+"([^"]+)"\)'), 'Linux applicationId');
  final windowsCompany = _capture(windowsRc,
      RegExp(r'VALUE\s+"CompanyName",\s*"([^"]+)"'), 'Windows CompanyName');

  /// Everything before the final dot, e.g. `com.salon` for
  /// `com.salon.salonAppView`.
  String orgPrefix(String id) => id.substring(0, id.lastIndexOf('.'));

  final iosApp = iosIds.where((id) => !id.contains('RunnerTests')).toSet();
  final iosTests = iosIds.where((id) => id.contains('RunnerTests')).toSet();
  final macosTests = macosIds.where((id) => id.contains('RunnerTests')).toSet();

  test('no platform falls back to the com.example placeholder', () {
    final all = <String>[
      androidId,
      androidNs,
      kotlinPkg,
      ...iosIds,
      ...macosIds,
      macosAppId,
      linuxId,
      windowsCompany,
    ];
    for (final id in all) {
      expect(id, isNotEmpty);
      expect(id, isNot(startsWith('com.example')),
          reason: 'com.example.* ids break the Google Cloud Console '
              'registration and cannot be published');
    }
  });

  test('Android applicationId, namespace and Kotlin package agree', () {
    expect(androidNs, androidId,
        reason: 'the Gradle namespace must match the applicationId');
    expect(kotlinPkg, androidId,
        reason: 'MainActivity.kt must live in the applicationId package');
  });

  test('every platform shares the Android organization prefix', () {
    final prefix = orgPrefix(androidId);
    expect(prefix, isNotEmpty);

    // RunnerTests ids carry one extra segment (`<app>.RunnerTests`).
    String appBase(String id) => id.endsWith('.RunnerTests')
        ? id.substring(0, id.length - '.RunnerTests'.length)
        : id;

    for (final id in iosIds) {
      expect(orgPrefix(appBase(id)), prefix,
          reason: 'iOS bundle id out of sync: $id');
    }
    for (final id in macosIds) {
      expect(orgPrefix(appBase(id)), prefix,
          reason: 'macOS bundle id out of sync: $id');
    }
    expect(orgPrefix(macosAppId), prefix);
    expect(orgPrefix(linuxId), prefix, reason: 'Linux applicationId out of sync');
    expect(windowsCompany, prefix, reason: 'Windows CompanyName out of sync');
  });

  test('Android and Linux share one id; iOS and macOS share the app id', () {
    expect(linuxId, androidId);
    expect(iosApp, isNotEmpty);
    expect(macosAppId, iosApp.first,
        reason: 'iOS and macOS must use the same app bundle id');
    expect(iosTests, isNotEmpty, reason: 'iOS RunnerTests id expected');
    expect(macosTests, isNotEmpty, reason: 'macOS RunnerTests id expected');
  });

  test('test targets extend the app bundle id', () {
    for (final id in iosTests) {
      expect(id, '${iosApp.first}.RunnerTests');
    }
    for (final id in macosTests) {
      expect(id, '$macosAppId.RunnerTests');
    }
  });
}
