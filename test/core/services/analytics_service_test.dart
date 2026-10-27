import 'package:flutter_test/flutter_test.dart';
import 'package:wakeup_app/core/services/analytics_service.dart';

void main() {
  setUp(() {
    AnalyticsService.reset();
  });

  tearDown(() {
    AnalyticsService.reset();
  });

  group('AnalyticsService — Safe No-Op Fallback (Unconfigured)', () {
    test('isInitialized is initially false when token is not configured', () {
      expect(AnalyticsService.isInitialized, isFalse);
    });

    test('init() completes without throwing and keeps isInitialized false when unconfigured', () async {
      await expectLater(AnalyticsService.init(), completes);
      expect(AnalyticsService.isInitialized, isFalse);
    });

    test('init() called repeatedly remains idempotent and does not throw', () async {
      await expectLater(AnalyticsService.init(), completes);
      await expectLater(AnalyticsService.init(), completes);
      await expectLater(AnalyticsService.init(), completes);
      expect(AnalyticsService.isInitialized, isFalse);
    });

    test('trackEvent() safely no-ops without throwing when unconfigured', () {
      expect(() => AnalyticsService.trackEvent('test_event'), returnsNormally);
      expect(
        () => AnalyticsService.trackEvent(
          'alarm_dismissed',
          properties: {
            'alarm_id': 42,
            'mission_completed': true,
            'dismiss_time': DateTime.now().toIso8601String(),
          },
        ),
        returnsNormally,
      );
      expect(
        () => AnalyticsService.trackEvent('empty_props', properties: {}),
        returnsNormally,
      );
    });

    test('identifyUser() safely no-ops without throwing when unconfigured', () {
      expect(() => AnalyticsService.identifyUser('user_anon_123'), returnsNormally);
      expect(() => AnalyticsService.identifyUser(''), returnsNormally);
    });

    test('setUserProperties() safely no-ops without throwing when unconfigured', () {
      expect(
        () => AnalyticsService.setUserProperties({
          'tier': 'free',
          'notifications_enabled': true,
          'alarm_count': 3,
        }),
        returnsNormally,
      );
      expect(() => AnalyticsService.setUserProperties({}), returnsNormally);
    });

    test('reset() executes cleanly without throwing when unconfigured', () {
      expect(() => AnalyticsService.reset(), returnsNormally);
      expect(AnalyticsService.isInitialized, isFalse);
      // Repeated resets are safe
      expect(() => AnalyticsService.reset(), returnsNormally);
      expect(AnalyticsService.isInitialized, isFalse);
    });

    test('full lifecycle sequence executes cleanly and safely when unconfigured', () async {
      expect(AnalyticsService.isInitialized, isFalse);

      await AnalyticsService.init();
      expect(AnalyticsService.isInitialized, isFalse);

      AnalyticsService.identifyUser('user_lifecycle_test');
      AnalyticsService.setUserProperties({'premium': false, 'theme': 'dark'});
      AnalyticsService.trackEvent('app_opened', properties: {'source': 'push'});
      AnalyticsService.trackEvent('alarm_created', properties: {'hour': 7, 'minute': 30});

      AnalyticsService.reset();
      expect(AnalyticsService.isInitialized, isFalse);
    });
  });
}
