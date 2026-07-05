-- First-time onboarding gate (spec: Splash/Login route on User.OnboardingCompletedAt).
-- Null = user must complete the post-login onboarding wizard.
alter table profiles add column onboarding_completed_at timestamptz;

-- Existing accounts predate onboarding — mark them complete so they aren't
-- forced through the wizard retroactively.
update profiles set onboarding_completed_at = now();
