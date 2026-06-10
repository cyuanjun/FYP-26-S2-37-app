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
