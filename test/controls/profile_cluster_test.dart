import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/boundaries/gateways/feedback_gateway.dart';
import 'package:wise_workout/boundaries/gateways/fitness_gateway.dart';
import 'package:wise_workout/boundaries/gateways/profile_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/manage_notification_prefs.dart';
import 'package:wise_workout/controls/request_password_reset.dart';
import 'package:wise_workout/controls/set_fitness_goal.dart';
import 'package:wise_workout/controls/submit_feedback.dart';
import 'package:wise_workout/controls/update_account_settings.dart';
import 'package:wise_workout/controls/update_fitness_profile.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/profile.dart';

import '../helpers/fakes.dart';

void main() {
  // ---- UpdateFitnessProfile (#13.1) ----
  group('UpdateFitnessProfile', () {
    test('save commits the patch via the gateway (positive)', () async {
      final fake = FakeFitnessGateway();
      final c = ProviderContainer(overrides: [
        fitnessGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('user-1'),
      ]);
      addTearDown(c.dispose);
      final ok = await c
          .read(updateFitnessProfileProvider.notifier)
          .save('user-1', {'height_cm': 170, 'sex': 'female'});
      expect(ok, isTrue);
      expect(fake.profilePatches.single['height_cm'], 170);
    });

    test('save surfaces gateway failure (negative)', () async {
      final fake = FakeFitnessGateway()..throwOnWrite = true;
      final c = ProviderContainer(
          overrides: [fitnessGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      final ok =
          await c.read(updateFitnessProfileProvider.notifier).save('user-1', {'height_cm': 170});
      expect(ok, isFalse);
      expect(c.read(updateFitnessProfileProvider).hasError, isTrue);
    });

    test('addCustomTag inserts and returns the tag (positive)', () async {
      final fake = FakeFitnessGateway();
      final c = ProviderContainer(
          overrides: [fitnessGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      final tag = await c.read(updateFitnessProfileProvider.notifier).addCustomTag(
          userId: 'user-1', kind: HealthTagKind.allergy, name: 'Sesame');
      expect(tag?.name, 'Sesame');
      expect(tag?.isCustom, isTrue);
      expect(fake.tags, hasLength(1));
    });

    test('addCustomTag rejects empty names (negative)', () async {
      final fake = FakeFitnessGateway();
      final c = ProviderContainer(
          overrides: [fitnessGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      final tag = await c
          .read(updateFitnessProfileProvider.notifier)
          .addCustomTag(userId: 'user-1', kind: HealthTagKind.diet, name: '   ');
      expect(tag, isNull);
      expect(fake.tags, isEmpty);
    });
  });

  // ---- SetFitnessGoal (#13.2) ----
  group('SetFitnessGoal', () {
    test('lose_weight goal writes kg target + timeline (positive)', () async {
      final fake = FakeFitnessGateway();
      final c = ProviderContainer(
          overrides: [fitnessGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      final ok = await c.read(setFitnessGoalProvider.notifier).save(
            userId: 'user-1',
            primaryGoal: PrimaryGoal.loseWeight,
            targetValue: 57,
            startingValue: 62,
            timelineWeeks: 12,
            weeklyCommitmentDays: 4,
          );
      expect(ok, isTrue);
      final values = fake.goalUpserts.single;
      expect(values['primary_goal'], 'lose_weight');
      expect(values['target_value'], 57);
      expect(values['target_unit'], 'kg');
      expect(values['timeline_weeks'], 12);
    });

    test('maintain_fitness nulls target + timeline (positive)', () async {
      final fake = FakeFitnessGateway();
      final c = ProviderContainer(
          overrides: [fitnessGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      final ok = await c.read(setFitnessGoalProvider.notifier).save(
            userId: 'user-1',
            primaryGoal: PrimaryGoal.maintainFitness,
            targetValue: 57, // ignored for maintenance
            timelineWeeks: 12,
            weeklyCommitmentDays: 3,
          );
      expect(ok, isTrue);
      final values = fake.goalUpserts.single;
      expect(values['target_value'], isNull);
      expect(values['target_unit'], isNull);
      expect(values['timeline_weeks'], isNull);
      expect(values['weekly_commitment_days'], 3);
    });

    test('weekly commitment out of 1–7 is rejected before the gateway (negative)', () async {
      final fake = FakeFitnessGateway();
      final c = ProviderContainer(
          overrides: [fitnessGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      final ok = await c.read(setFitnessGoalProvider.notifier).save(
            userId: 'user-1',
            primaryGoal: PrimaryGoal.maintainFitness,
            weeklyCommitmentDays: 9,
          );
      expect(ok, isFalse);
      expect(fake.goalUpserts, isEmpty);
    });

    test('gateway failure → false + error state (negative)', () async {
      final fake = FakeFitnessGateway()..throwOnWrite = true;
      final c = ProviderContainer(
          overrides: [fitnessGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      final ok = await c.read(setFitnessGoalProvider.notifier).save(
            userId: 'user-1',
            primaryGoal: PrimaryGoal.buildMuscle,
            targetValue: 66,
            weeklyCommitmentDays: 4,
          );
      expect(ok, isFalse);
    });
  });

  // ---- SubmitFeedback (#13.5) ----
  group('SubmitFeedback', () {
    ProviderContainer feedbackContainer(FakeFeedbackGateway fake, {String? userId = 'user-1'}) {
      final c = ProviderContainer(overrides: [
        feedbackGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue(userId),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('valid body submits trimmed (positive)', () async {
      final fake = FakeFeedbackGateway();
      final c = feedbackContainer(fake);
      final ok = await c
          .read(submitFeedbackProvider.notifier)
          .submit(category: FeedbackCategory.bug, body: '  The timer drifts on pause.  ');
      expect(ok, isTrue);
      expect(fake.submissions.single.$2, FeedbackCategory.bug);
      expect(fake.submissions.single.$3, 'The timer drifts on pause.');
    });

    test('under 10 chars after trim never reaches the gateway (negative)', () async {
      final fake = FakeFeedbackGateway();
      final c = feedbackContainer(fake);
      final ok = await c
          .read(submitFeedbackProvider.notifier)
          .submit(category: FeedbackCategory.general, body: '   short    ');
      expect(ok, isFalse);
      expect(fake.submissions, isEmpty);
    });

    test('signed out → false (negative)', () async {
      final fake = FakeFeedbackGateway();
      final c = feedbackContainer(fake, userId: null);
      final ok = await c
          .read(submitFeedbackProvider.notifier)
          .submit(category: FeedbackCategory.general, body: 'long enough body text');
      expect(ok, isFalse);
      expect(fake.submissions, isEmpty);
    });

    test('gateway failure → false (negative)', () async {
      final fake = FakeFeedbackGateway()..throwOnSubmit = true;
      final c = feedbackContainer(fake);
      final ok = await c
          .read(submitFeedbackProvider.notifier)
          .submit(category: FeedbackCategory.featureRequest, body: 'please add dark charts');
      expect(ok, isFalse);
    });
  });

  // ---- ManageNotificationPrefs (#13.4) ----
  group('ManageNotificationPrefs', () {
    Profile profileWith(Map<String, dynamic> prefs) => Profile(
        id: 'user-1',
        email: 'mia@test',
        role: UserRole.free,
        firstName: 'Mia',
        notificationPrefs: prefs);

    ProviderContainer prefsContainer(FakeProfileGateway fake, Profile profile) {
      final c = ProviderContainer(overrides: [
        profileGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('user-1'),
        currentProfileProvider.overrideWith((ref) async => profile),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('build merges stored prefs over defaults (positive)', () async {
      final fake = FakeProfileGateway();
      final c = prefsContainer(fake, profileWith({'promotions': true, 'daily_reminder': false}));
      final prefs = await c.read(notificationPrefsProvider.future);
      expect(prefs['promotions'], isTrue); // stored override
      expect(prefs['daily_reminder'], isFalse); // stored override
      expect(prefs['weekly_summary'], isTrue); // default
      expect(prefs['product_tips'], isFalse); // default (marketing off)
    });

    test('setEnabled writes the whole map (positive)', () async {
      final fake = FakeProfileGateway();
      final c = prefsContainer(fake, profileWith({}));
      await c.read(notificationPrefsProvider.future);
      await c.read(notificationPrefsProvider.notifier).setEnabled('promotions', true);
      expect(fake.prefsWrites.single['promotions'], isTrue);
      expect(c.read(notificationPrefsProvider).value?['promotions'], isTrue);
    });
  });

  // ---- UpdateAccountSettings (#13.3) ----
  group('UpdateAccountSettings', () {
    test('setPreferredUnits writes instantly (positive)', () async {
      final fake = FakeProfileGateway();
      final c = ProviderContainer(overrides: [
        profileGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('user-1'),
      ]);
      addTearDown(c.dispose);
      await c
          .read(updateAccountSettingsProvider.notifier)
          .setPreferredUnits(PreferredUnits.imperial);
      expect(fake.unitWrites.single, PreferredUnits.imperial);
    });

    test('setPreferredUnits is a no-op when signed out (negative)', () async {
      final fake = FakeProfileGateway();
      final c = ProviderContainer(overrides: [
        profileGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue(null),
      ]);
      addTearDown(c.dispose);
      await c
          .read(updateAccountSettingsProvider.notifier)
          .setPreferredUnits(PreferredUnits.imperial);
      expect(fake.unitWrites, isEmpty);
    });

    test('sendChangePasswordEmail success/failure', () async {
      final fake = FakeAuthGateway();
      final c = ProviderContainer(
          overrides: [authGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      expect(
          await c
              .read(updateAccountSettingsProvider.notifier)
              .sendChangePasswordEmail('mia@test'),
          isTrue);
      expect(fake.resetEmails, ['mia@test']);

      fake.throwOnReset = true;
      expect(
          await c
              .read(updateAccountSettingsProvider.notifier)
              .sendChangePasswordEmail('mia@test'),
          isFalse);
    });
  });

  // ---- RequestPasswordReset (#4) ----
  group('RequestPasswordReset', () {
    test('send delegates to the gateway (positive)', () async {
      final fake = FakeAuthGateway();
      final c = ProviderContainer(
          overrides: [authGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      await c.read(requestPasswordResetProvider.notifier).send('mia@test');
      expect(fake.resetEmails, ['mia@test']);
      expect(c.read(requestPasswordResetProvider).hasError, isFalse);
    });

    test('gateway failure is swallowed — same "sent" outcome (anti-enumeration)', () async {
      final fake = FakeAuthGateway()..throwOnReset = true;
      final c = ProviderContainer(
          overrides: [authGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      await c.read(requestPasswordResetProvider.notifier).send('unknown@test');
      expect(c.read(requestPasswordResetProvider).hasError, isFalse);
    });
  });
}
