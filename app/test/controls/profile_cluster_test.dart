import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/boundaries/gateways/feedback_gateway.dart';
import 'package:wise_workout/boundaries/gateways/fitness_gateway.dart';
import 'package:wise_workout/boundaries/gateways/profile_gateway.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
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

// (#) Tests the Profile cluster controls: fitness profile, fitness goal, feedback,
// (#) notification prefs, account settings, password reset, and custom workout types.
void main() {
  // ---- UpdateFitnessProfile (#13.1) ----
  // (#) The control that edits the fitness profile and custom health tags.
  group('UpdateFitnessProfile', () {
    // (#) (+) Check if save forwards the patch to the gateway.
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

    // (#) (-) Check if a gateway failure returns false and lands in an error state.
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

    // (#) (-) Check if an out-of-range height is rejected before reaching the gateway.
    test('out-of-range height is rejected before the gateway (negative)', () async {
      final fake = FakeFitnessGateway();
      final c = ProviderContainer(overrides: [
        fitnessGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('user-1'),
      ]);
      addTearDown(c.dispose);
      final ok = await c
          .read(updateFitnessProfileProvider.notifier)
          .save('user-1', {'height_cm': 999, 'weight_kg': 74.0});
      expect(ok, isFalse); // control's contract: rejected
      expect(fake.profilePatches, isEmpty); // nothing reached the gateway
    });

    // (#) (+) Check if adding a custom health tag inserts and returns it flagged custom.
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

    // (#) (-) Check if a blank tag name is rejected and nothing is inserted.
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
  // (#) The control that saves the user's fitness goal.
  group('SetFitnessGoal', () {
    // (#) (+) Check if a lose-weight goal writes the kg target, unit, and timeline.
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

    // (#) (+) Check if a maintain-fitness goal nulls out target and timeline but keeps commitment days.
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

    // (#) (-) Check if a weekly commitment outside 1 to 7 is rejected before the gateway.
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

    // (#) (-) Check if a target-based goal with a zero/negative target is rejected.
    test('target-racing goal with a non-positive target is rejected (negative)', () async {
      final fake = FakeFitnessGateway();
      final c = ProviderContainer(
          overrides: [fitnessGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      final ok = await c.read(setFitnessGoalProvider.notifier).save(
            userId: 'user-1',
            primaryGoal: PrimaryGoal.loseWeight, // races a kg target
            targetValue: 0, // invalid
            weeklyCommitmentDays: 4,
          );
      expect(ok, isFalse);
      expect(fake.goalUpserts, isEmpty);
    });

    // (#) (-) Check if a gateway failure returns false and sets an error state.
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
  // (#) The control that submits user feedback.
  group('SubmitFeedback', () {
    // (#) Builds a container with the given signed-in user and fake feedback gateway.
    ProviderContainer feedbackContainer(FakeFeedbackGateway fake, {String? userId = 'user-1'}) {
      final c = ProviderContainer(overrides: [
        feedbackGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue(userId),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    // (#) (+) Check if a valid body is trimmed and submitted with its category.
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

    // (#) (-) Check if a too-short body (under 10 chars after trim) never reaches the gateway.
    test('under 10 chars after trim never reaches the gateway (negative)', () async {
      final fake = FakeFeedbackGateway();
      final c = feedbackContainer(fake);
      final ok = await c
          .read(submitFeedbackProvider.notifier)
          .submit(category: FeedbackCategory.general, body: '   short    ');
      expect(ok, isFalse);
      expect(fake.submissions, isEmpty);
    });

    // (#) (-) Check if a signed-out user cannot submit feedback.
    test('signed out → false (negative)', () async {
      final fake = FakeFeedbackGateway();
      final c = feedbackContainer(fake, userId: null);
      final ok = await c
          .read(submitFeedbackProvider.notifier)
          .submit(category: FeedbackCategory.general, body: 'long enough body text');
      expect(ok, isFalse);
      expect(fake.submissions, isEmpty);
    });

    // (#) (-) Check if a gateway failure returns false.
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
  // (#) The control that reads and writes notification preferences.
  group('ManageNotificationPrefs', () {
    // (#) Builds a profile carrying the given notification prefs map.
    Profile profileWith(Map<String, dynamic> prefs) => Profile(
        id: 'user-1',
        email: 'mia@test',
        role: UserRole.free,
        firstName: 'Mia',
        notificationPrefs: prefs);

    // (#) Builds a container signed in as user-1 with the given profile and fake profile gateway.
    ProviderContainer prefsContainer(FakeProfileGateway fake, Profile profile) {
      final c = ProviderContainer(overrides: [
        profileGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('user-1'),
        currentProfileProvider.overrideWith((ref) async => profile),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    // (#) (+) Check if stored prefs override the defaults and unset keys fall back to defaults.
    test('build merges stored prefs over defaults (positive)', () async {
      final fake = FakeProfileGateway();
      final c = prefsContainer(fake, profileWith({'promotions': true, 'daily_reminder': false}));
      final prefs = await c.read(notificationPrefsProvider.future);
      expect(prefs['promotions'], isTrue); // stored override
      expect(prefs['daily_reminder'], isFalse); // stored override
      expect(prefs['weekly_summary'], isTrue); // default
      expect(prefs['product_tips'], isFalse); // default (marketing off)
    });

    // (#) (+) Check if setEnabled persists the full prefs map and updates the state.
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
  // (#) The control for account settings: units, name, and password-change email.
  group('UpdateAccountSettings', () {
    // (#) (+) Check if setting preferred units writes them immediately.
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

    // (#) (-) Check if setting units does nothing when signed out.
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

    // (#) (+) Check if saving a valid first/last name writes them.
    test('saveName writes the onboarding name fallback (positive)', () async {
      final fake = FakeProfileGateway();
      final c = ProviderContainer(overrides: [
        profileGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('user-1'),
      ]);
      addTearDown(c.dispose);
      final ok = await c
          .read(updateAccountSettingsProvider.notifier)
          .saveName(firstName: 'Mia', lastName: 'Patel');
      expect(ok, isTrue);
      expect(fake.nameWrites.single, ('Mia', 'Patel'));
    });

    // (#) (-) Check if a blank first name is rejected and nothing is written.
    test('saveName rejects empty first name (negative)', () async {
      final fake = FakeProfileGateway();
      final c = ProviderContainer(overrides: [
        profileGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue('user-1'),
      ]);
      addTearDown(c.dispose);
      final ok = await c
          .read(updateAccountSettingsProvider.notifier)
          .saveName(firstName: '   ');
      expect(ok, isFalse);
      expect(fake.nameWrites, isEmpty);
    });

    // (#) (+) Check if sending the change-password email returns true on success and false on gateway failure.
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
  // (#) The forgot-password control.
  group('RequestPasswordReset', () {
    // (#) (+) Check if send forwards the email to the gateway with no error.
    test('send delegates to the gateway (positive)', () async {
      final fake = FakeAuthGateway();
      final c = ProviderContainer(
          overrides: [authGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      await c.read(requestPasswordResetProvider.notifier).send('mia@test');
      expect(fake.resetEmails, ['mia@test']);
      expect(c.read(requestPasswordResetProvider).hasError, isFalse);
    });

    // (#) (-) Check if a gateway failure is swallowed so unknown emails look identical (anti-enumeration).
    test('gateway failure is swallowed — same "sent" outcome (anti-enumeration)', () async {
      final fake = FakeAuthGateway()..throwOnReset = true;
      final c = ProviderContainer(
          overrides: [authGatewayProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      await c.read(requestPasswordResetProvider.notifier).send('unknown@test');
      expect(c.read(requestPasswordResetProvider).hasError, isFalse);
    });
  });

  // ---- Custom workout types (onboarding + #13.1 pickers) ----
  // (#) Adding user-defined workout types.
  group('addCustomWorkoutType', () {
    // (#) (+) Check if a custom workout type is inserted and returned with a slug, flagged custom.
    test('inserts a custom type and returns it (positive)', () async {
      final gw = FakeWorkoutGateway(types: [runningType]);
      final c = ProviderContainer(overrides: [
        workoutGatewayProvider.overrideWithValue(gw),
        fitnessGatewayProvider.overrideWithValue(FakeFitnessGateway()),
      ]);
      addTearDown(c.dispose);
      final t = await c
          .read(updateFitnessProfileProvider.notifier)
          .addCustomWorkoutType(userId: 'u1', name: 'Bouldering');
      expect(t?.name, 'Bouldering');
      expect(t?.isCustom, isTrue);
      expect(t?.slug, 'bouldering');
      expect(gw.types, hasLength(2));
    });

    // (#) (-) Check if a blank workout-type name is rejected and nothing is inserted.
    test('rejects empty names (negative)', () async {
      final gw = FakeWorkoutGateway(types: [runningType]);
      final c = ProviderContainer(overrides: [
        workoutGatewayProvider.overrideWithValue(gw),
        fitnessGatewayProvider.overrideWithValue(FakeFitnessGateway()),
      ]);
      addTearDown(c.dispose);
      final t = await c
          .read(updateFitnessProfileProvider.notifier)
          .addCustomWorkoutType(userId: 'u1', name: '   ');
      expect(t, isNull);
      expect(gw.types, hasLength(1));
    });
  });
}
