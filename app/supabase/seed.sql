-- Wise Workout (FYP-26-S2-37) — seed data
-- Runs after migrations (supabase db reset / supabase start). Idempotent.
--
-- Seeds the three install-time CATALOGS only. User/athlete/expert demo data is NOT seeded here:
-- every such row hangs off auth.users (profiles.id → auth.users.id), so demo accounts are created
-- via Supabase Auth (signup on the marketing site, or `supabase auth` / the dashboard) and then
-- enriched through the app's controls. See supabase/README.md.

-- ----------------------------------------------------------------------------
-- Workout types (catalog) — slug drives the rendered glyph (iconForSlug)
-- ----------------------------------------------------------------------------
insert into workout_types (name, slug, is_custom) values
  ('Running',  'running',  false),
  ('Cycling',  'cycling',  false),
  ('Strength', 'strength', false),
  ('Yoga',     'yoga',     false),
  ('Swimming', 'swimming', false),
  ('Walking',  'walking',  false),
  ('HIIT',     'hiit',     false),
  ('Pilates',  'pilates',  false),
  ('Rowing',   'rowing',   false),
  ('Hiking',   'hiking',   false)
on conflict (slug) do nothing;

-- ----------------------------------------------------------------------------
-- Health tags (catalog) — one table, discriminated by kind (#13.1 chip rows)
-- ----------------------------------------------------------------------------
insert into health_tags (kind, name, is_custom) values
  -- diet
  ('diet',    'Vegetarian',   false),
  ('diet',    'Vegan',        false),
  ('diet',    'Keto',         false),
  ('diet',    'Paleo',        false),
  ('diet',    'Halal',        false),
  ('diet',    'Gluten-Free',  false),
  ('diet',    'Dairy-Free',   false),
  -- allergy
  ('allergy', 'Nuts',         false),
  ('allergy', 'Dairy',        false),
  ('allergy', 'Shellfish',    false),
  ('allergy', 'Gluten',       false),
  ('allergy', 'Eggs',         false),
  ('allergy', 'Soy',          false),
  -- injury
  ('injury',  'Knee pain',    false),
  ('injury',  'Lower back',   false),
  ('injury',  'Shoulder',     false),
  ('injury',  'Ankle',        false),
  ('injury',  'Wrist',        false)
on conflict (kind, name) do nothing;

-- ----------------------------------------------------------------------------
-- Expert categories (catalog) — stable slugs (the original expert_specialty enum),
-- admin-curated on #29. Referenced by expert_profiles.specialties + expert_services.category.
-- ----------------------------------------------------------------------------
insert into expert_categories (id, label, description, is_active) values
  ('strength',  'Strength',  'Resistance training, hypertrophy, and powerlifting programming.', true),
  ('endurance', 'Endurance', 'Aerobic base, tempo, and long-distance conditioning.',           true),
  ('mobility',  'Mobility',  'Flexibility, joint range of motion, and movement quality.',        true),
  ('nutrition', 'Nutrition', 'Meal planning, body-composition, and dietary guidance.',           true),
  ('running',   'Running',   'Run coaching — form, pacing, and race preparation.',               true),
  ('recovery',  'Recovery',  'Rest, mobility work, and return-from-injury protocols.',           true)
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- Public challenges catalog (created_by_user_id null = curator-seeded, #11).
-- Fixed ids => idempotent; windows recomputed relative to now() on each run
-- (on conflict UPDATE refreshes them so re-seeding keeps challenges live).
-- ----------------------------------------------------------------------------
insert into challenges (id, created_by_user_id, name, short_name, description, icon,
                        visibility, metric_kind, metric, target_value, workout_type_id,
                        started_at, ended_at) values
  ('c0000000-0000-4000-8000-000000000001', null, 'Run 100 km this month', 'RUN 100K',
   'Log 100 km of running before the window closes.', '🏃', 'public', 'accumulator',
   'total_distance', 100000, (select id from workout_types where slug = 'running'),
   date_trunc('day', now()) - interval '10 days', date_trunc('day', now()) + interval '20 days'),
  ('c0000000-0000-4000-8000-000000000002', null, '20 workouts in 30 days', '20 IN 30',
   'Any workout counts — consistency wins.', '⚡', 'public', 'accumulator',
   'total_sessions', 20, null,
   date_trunc('day', now()) - interval '7 days',  date_trunc('day', now()) + interval '23 days'),
  ('c0000000-0000-4000-8000-000000000003', null, 'Fastest 5K', 'FAST 5K',
   'Best single running time wins.', '🎯', 'public', 'best_of',
   'fastest_time', null, (select id from workout_types where slug = 'running'),
   date_trunc('day', now()) - interval '3 days',  date_trunc('day', now()) + interval '11 days'),
  ('c0000000-0000-4000-8000-000000000004', null, 'Longest single ride', 'LONG RIDE',
   'One ride, as far as you can go.', '🚴', 'public', 'best_of',
   'longest_distance', null, (select id from workout_types where slug = 'cycling'),
   date_trunc('day', now()) - interval '5 days',  date_trunc('day', now()) + interval '9 days'),
  ('c0000000-0000-4000-8000-000000000005', null, 'Burn 5,000 kcal', 'BURN 5K',
   'Any workout type counts toward the burn.', '🔥', 'public', 'accumulator',
   'total_calories', 5000, null,
   date_trunc('day', now()) - interval '14 days', date_trunc('day', now()) + interval '16 days')
on conflict (id) do update set
  name = excluded.name, short_name = excluded.short_name, description = excluded.description,
  icon = excluded.icon, target_value = excluded.target_value,
  started_at = excluded.started_at, ended_at = excluded.ended_at;

-- ============================================================================
-- LANDING SITE — pricing display copy (web/ marketing site). Display text
-- only; premium price mirrors the settled $9.99/mo figure.
-- ============================================================================

insert into landing_pricing_plans
  (plan_key, plan_name, price_label, description, button_text, button_url, features, display_order, is_active)
values
  ('free', 'Free tier', '$0/mth', 'Basic tracking and summaries', 'Choose plan', '/login',
   array['Workout activity logging', 'Basic workout history', 'Limited AI progress summaries',
         'Browse verified experts', 'Access FAQ and contact support'], 1, true),
  ('premium', 'Premium tier', '$9.99/mth', 'Advanced analytics and personalised AI', 'Choose plan', '/login',
   array['Everything in Free', 'Unlimited AI progress summaries', 'Personalised plan suggestions',
         'Advanced progress statistics', 'Priority reminder and goal tools', 'Premium support'], 2, true),
  ('expert_services', 'Expert services', 'Add-on', 'Separate paid expert services', 'Explore', '/login',
   array['Available to Free and Premium', 'Request verified experts by category',
         'Custom coaching or nutrition plans', 'Direct expert feedback',
         'Service add-ons for events or specialist goals'], 3, true)
on conflict (plan_key) do update set
  plan_name = excluded.plan_name, price_label = excluded.price_label,
  description = excluded.description, button_text = excluded.button_text,
  button_url = excluded.button_url, features = excluded.features,
  display_order = excluded.display_order, is_active = excluded.is_active,
  updated_at = now();

insert into landing_faqs (faq_key, question, answer, display_order, is_active) values
  ('free-tier', 'Can I use Wise Workout for free?',
   'Yes. Free users can log workouts, view basic workout history, browse verified experts, and access limited AI progress summaries.', 1, true),
  ('premium-adds', 'What does the premium plan add?',
   'Premium adds unlimited AI progress summaries, personalised plan suggestions, advanced progress statistics, priority reminders, and premium support.', 2, true),
  ('expert-services', 'How do expert services work?',
   'Users can browse featured experts by category and request paid coaching, nutrition, recovery, or specialist event support as separate add-ons.', 3, true),
  ('admin-managed', 'Can administrators update this landing page?',
   'Yes. Pricing details, testimonials, FAQs, and expert information are managed live from the admin portal against the shared database.', 4, true)
on conflict (faq_key) do update set
  question = excluded.question, answer = excluded.answer,
  display_order = excluded.display_order, is_active = excluded.is_active,
  updated_at = now();
