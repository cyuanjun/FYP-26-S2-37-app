-- Public-safe landing page metrics.
-- Draft migration for the shared FYP-26-S2-37-app Supabase/Postgres database.
--
-- Keep this view limited to counts that are safe to display publicly.

create view landing_metric_summary as
select
  (select count(*) from profiles) as total_users,
  (select count(*) from profiles where role = 'free') as free_users,
  (select count(*) from profiles where role = 'premium') as premium_users,
  (select count(*) from expert_profiles where verification_status = 'verified') as verified_experts,
  (select count(*) from expert_categories where is_active = true) as active_categories,
  (select count(*) from public_testimonials where status = 'approved') as approved_public_testimonials,
  (
    select coalesce(round(avg(rating)::numeric, 1), 0)
    from public_testimonials
    where status = 'approved'
  ) as average_public_testimonial_rating,
  (select count(*) from expert_reviews) as expert_review_count,
  (select count(*) from contact_messages where status = 'resolved') as resolved_contact_messages;

-- In Supabase, views run with the privileges of the view owner by default.
-- Keep this view public-safe and do not add sensitive fields.
