-- Admin write policies should allow admins to leave rows owned by the target
-- user. The original policies allowed admin rows in USING, but their WITH
-- CHECK predicates still required the row owner to be auth.uid(), so admin
-- updates for another user failed at the final RLS check.

drop policy fitness_profiles_owner on fitness_profiles;
create policy fitness_profiles_owner on fitness_profiles
  for all to authenticated
  using (id = auth.uid() or is_admin())
  with check (id = auth.uid() or is_admin());

drop policy fitness_goals_owner on fitness_goals;
create policy fitness_goals_owner on fitness_goals
  for all to authenticated
  using (user_id = auth.uid() or is_admin())
  with check (user_id = auth.uid() or is_admin());

drop policy fitness_plans_owner on fitness_plans;
create policy fitness_plans_owner on fitness_plans
  for all to authenticated
  using (user_id = auth.uid() or is_admin())
  with check (user_id = auth.uid() or is_admin());

drop policy planned_workouts_owner on planned_workouts;
create policy planned_workouts_owner on planned_workouts
  for all to authenticated
  using (
    exists (
      select 1 from fitness_plans fp
      where fp.id = fitness_plan_id and (fp.user_id = auth.uid() or is_admin())
    )
  )
  with check (
    exists (
      select 1 from fitness_plans fp
      where fp.id = fitness_plan_id and (fp.user_id = auth.uid() or is_admin())
    )
  );

drop policy connected_devices_owner on connected_devices;
create policy connected_devices_owner on connected_devices
  for all to authenticated
  using (user_id = auth.uid() or is_admin())
  with check (user_id = auth.uid() or is_admin());

drop policy posts_author_write on posts;
create policy posts_author_write on posts
  for all to authenticated
  using (user_id = auth.uid() or is_admin())
  with check (user_id = auth.uid() or is_admin());

drop policy post_comments_author on post_comments;
create policy post_comments_author on post_comments
  for all to authenticated
  using (user_id = auth.uid() or is_admin())
  with check (user_id = auth.uid() or is_admin());

drop policy challenges_creator on challenges;
create policy challenges_creator on challenges
  for all to authenticated
  using (created_by_user_id = auth.uid() or is_admin())
  with check (created_by_user_id = auth.uid() or is_admin());

drop policy expert_profiles_owner on expert_profiles;
create policy expert_profiles_owner on expert_profiles
  for all to authenticated
  using (id = auth.uid() or is_admin())
  with check (id = auth.uid() or is_admin());

drop policy expert_services_owner_write on expert_services;
create policy expert_services_owner_write on expert_services
  for all to authenticated
  using (expert_user_id = auth.uid() or is_admin())
  with check (expert_user_id = auth.uid() or is_admin());

drop policy expert_reviews_author on expert_reviews;
create policy expert_reviews_author on expert_reviews
  for all to authenticated
  using (user_id = auth.uid() or is_admin())
  with check (user_id = auth.uid() or is_admin());

drop policy expert_docs_owner_or_admin on expert_verification_documents;
create policy expert_docs_owner_or_admin on expert_verification_documents
  for all to authenticated
  using (user_id = auth.uid() or is_admin())
  with check (user_id = auth.uid() or is_admin());

drop policy deliverables_expert_write on deliverables;
create policy deliverables_expert_write on deliverables
  for all to authenticated
  using (
    exists (
      select 1 from service_requests sr
      where sr.id = service_request_id and (sr.expert_user_id = auth.uid() or is_admin())
    )
  )
  with check (
    exists (
      select 1 from service_requests sr
      where sr.id = service_request_id and (sr.expert_user_id = auth.uid() or is_admin())
    )
  );

drop policy subscriptions_owner on subscriptions;
create policy subscriptions_owner on subscriptions
  for all to authenticated
  using (id = auth.uid() or is_admin())
  with check (id = auth.uid() or is_admin());
