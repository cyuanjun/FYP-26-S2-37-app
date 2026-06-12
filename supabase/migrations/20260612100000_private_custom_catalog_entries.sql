-- Custom catalog entries are private to their creator (workout types + health
-- tags). Stock entries (is_custom = false) stay visible to everyone; admins
-- see all. Note for the future social feed: if shared posts ever need to show
-- another user's custom type name, expose it via a dedicated view rather than
-- relaxing these policies.

drop policy workout_types_read on workout_types;
create policy workout_types_read on workout_types
  for select to authenticated
  using (not is_custom or created_by_user_id = auth.uid() or is_admin());

drop policy health_tags_read on health_tags;
create policy health_tags_read on health_tags
  for select to authenticated
  using (not is_custom or created_by_user_id = auth.uid() or is_admin());
