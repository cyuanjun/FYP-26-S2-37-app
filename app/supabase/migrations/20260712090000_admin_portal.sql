-- Admin portal (web/#/admin) backend surface. Most admin writes already work
-- through existing is_admin() policies (profiles role/status, categories,
-- testimonials, pricing, contact, feedback, verification documents). This
-- migration adds the two missing pieces:
--   • expert application review — expert_profiles.verification_status is
--     column-locked (20260708100000), so approval/rejection is an RPC; an
--     approval also flips profiles.role to 'expert' (the role guard allows
--     admins).
--   • expert_services moderation — writes were owner-only and reads
--     live-or-owner; admins get full read/write (US59 monitor listings).

-- ============================================================================
-- 1. REVIEW EXPERT APPLICATION (US52 / US57)
-- ============================================================================

create or replace function public.review_expert_application(p_expert uuid, p_approve boolean)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_status verification_status;
begin
  if not is_admin() then
    raise exception 'Only admins can review expert applications';
  end if;

  select verification_status into v_status
  from expert_profiles where id = p_expert for update;

  if v_status is null then
    raise exception 'No expert application for this user';
  end if;
  if v_status <> 'pending' then
    raise exception 'Application already %', v_status;
  end if;

  if p_approve then
    update expert_profiles set verification_status = 'verified' where id = p_expert;
    update profiles set role = 'expert' where id = p_expert;
  else
    update expert_profiles set verification_status = 'rejected' where id = p_expert;
  end if;
end;
$$;

revoke all on function public.review_expert_application(uuid, boolean) from public, anon;
grant execute on function public.review_expert_application(uuid, boolean) to authenticated;

-- ============================================================================
-- 2. LISTINGS MODERATION (US59)
-- ============================================================================

create policy expert_services_admin_all on expert_services
  for all to authenticated using (is_admin()) with check (is_admin());
