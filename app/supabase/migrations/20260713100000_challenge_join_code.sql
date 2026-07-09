-- Challenge join codes (#11 / US25).
-- Every challenge gets a short, shareable, ambiguity-free code so users can
-- search + join a challenge (public or invite-only) without browsing. The
-- code is server-assigned on insert and unique; the app never generates it.

alter table public.challenges add column join_code text;

-- 6-char uppercase code from an ambiguity-free alphabet (no 0/O/1/I/L) so it
-- survives being read aloud or typed from a screenshot.
create or replace function public.gen_challenge_code()
returns text
language plpgsql
volatile
as $$
declare
  alphabet constant text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  out text := '';
begin
  for i in 1..6 loop
    out := out || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
  end loop;
  return out;
end;
$$;

-- Assign a unique code on insert when the client didn't supply one; retry on
-- the (rare) collision so the unique index below never rejects a valid insert.
create or replace function public.assign_challenge_code()
returns trigger
language plpgsql
as $$
declare
  candidate text;
begin
  if new.join_code is not null then
    return new;
  end if;
  loop
    candidate := public.gen_challenge_code();
    exit when not exists (select 1 from public.challenges where join_code = candidate);
  end loop;
  new.join_code := candidate;
  return new;
end;
$$;

create trigger trg_assign_challenge_code
  before insert on public.challenges
  for each row execute function public.assign_challenge_code();

-- Backfill existing challenges.
do $$
declare
  r record;
  candidate text;
begin
  for r in select id from public.challenges where join_code is null loop
    loop
      candidate := public.gen_challenge_code();
      exit when not exists (select 1 from public.challenges where join_code = candidate);
    end loop;
    update public.challenges set join_code = candidate where id = r.id;
  end loop;
end $$;

alter table public.challenges alter column join_code set not null;
create unique index uq_challenges_join_code on public.challenges (join_code);
