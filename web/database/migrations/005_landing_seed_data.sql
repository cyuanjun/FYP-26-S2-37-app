-- Demo seed data for landing page tables.
-- Draft seed migration for local development and presentation.
--
-- This assumes the app's base seed already creates profiles, expert profiles,
-- categories, and reviews. Add real UUIDs from that seed before applying.

insert into landing_pricing_plans (
  plan_key,
  plan_name,
  price_label,
  description,
  button_text,
  button_url,
  features,
  display_order,
  is_active
) values
  (
    'free',
    'Free tier',
    '$0/mth',
    'Basic tracking and summaries',
    'Choose plan',
    '/register',
    array[
      'Workout activity logging',
      'Basic workout history',
      'Limited AI progress summaries',
      'Browse verified experts',
      'Access FAQ and contact support'
    ],
    1,
    true
  ),
  (
    'premium',
    'Premium tier',
    '$9.90/mth',
    'Advanced analytics and personalised AI',
    'Choose plan',
    '/register',
    array[
      'Everything in Free',
      'Unlimited AI progress summaries',
      'Personalised plan suggestions',
      'Advanced progress statistics',
      'Priority reminder and goal tools',
      'Premium support'
    ],
    2,
    true
  ),
  (
    'expert_services',
    'Expert services',
    'Add-on',
    'Separate paid expert services',
    'Explore',
    '/register',
    array[
      'Everything in Premium',
      'Request verified experts by category',
      'Custom coaching or nutrition plans',
      'Direct expert feedback',
      'Service add-ons for events or specialist goals'
    ],
    3,
    true
  )
on conflict (plan_key) do update set
  plan_name = excluded.plan_name,
  price_label = excluded.price_label,
  description = excluded.description,
  button_text = excluded.button_text,
  button_url = excluded.button_url,
  features = excluded.features,
  display_order = excluded.display_order,
  is_active = excluded.is_active,
  updated_at = now();

-- Replace placeholder profile UUIDs before applying this block.
-- insert into public_testimonials (
--   user_id,
--   display_name,
--   user_category,
--   rating,
--   body,
--   status,
--   submitted_at,
--   reviewed_at
-- ) values
--   (
--     '00000000-0000-0000-0000-000000000001',
--     'Jamie L.',
--     'Premium runner',
--     5,
--     'Wise Workout helped me keep my training consistent. The progress summaries make it much easier to understand what changed week by week.',
--     'approved',
--     now(),
--     now()
--   );
