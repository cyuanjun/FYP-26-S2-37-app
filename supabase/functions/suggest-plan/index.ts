// SuggestPlan AI proxy (STUB) — the second AI surface (build-plan §5).
//
// Serves BOTH tiers (decided 12 Jun): Free gets a basic AI plan, Premium a
// personalised one — same mechanics in the stub, different depth/labelling;
// with a real model the tier controls prompt depth. Reads the caller's own
// fitness profile + active goal (RLS-scoped via their JWT). Deterministic —
// no API key needed. To go live, replace `buildStubPlan` with an
// OpenAI/Gemini call using the same `profile`/`goal` payload — the app
// contract (AiGateway → this function) does not change.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface Goal {
  primary_goal: string;
  weekly_commitment_days: number | null;
  timeline_weeks: number | null;
}
interface Profile {
  activity_level: string | null;
  training_experience: string | null;
  preferred_workout_type_ids: string[];
}

// Day spread for n workouts/week (1=Mon … 7=Sun).
const DAY_SPREAD: Record<number, number[]> = {
  1: [3], 2: [2, 5], 3: [1, 3, 5], 4: [1, 3, 5, 6],
  5: [1, 2, 4, 5, 6], 6: [1, 2, 3, 4, 5, 6], 7: [1, 2, 3, 4, 5, 6, 7],
};

function buildStubPlan(goal: Goal, profile: Profile, preferredSlugs: string[], personalised: boolean) {
  const days = Math.min(Math.max(goal.weekly_commitment_days ?? 3, 1), 7);
  const weeks = goal.timeline_weeks ?? 4;
  const exp = profile.training_experience ?? "beginner";
  const base = exp === "advanced" ? 50 : exp === "intermediate" ? 40 : 30;

  // Slug rotation per goal — preferred types first, goal-typical fillers after.
  const fillers: Record<string, string[]> = {
    lose_weight: ["running", "cycling", "hiit"],
    build_muscle: ["strength", "strength", "hiit"],
    improve_endurance: ["running", "cycling", "rowing"],
    maintain_fitness: ["running", "strength", "yoga"],
  };
  const rotation = [...new Set([...preferredSlugs, ...(fillers[goal.primary_goal] ?? fillers.maintain_fitness)])];

  const titles: Record<string, string> = {
    lose_weight: "Lean & Consistent",
    build_muscle: "Progressive Strength",
    improve_endurance: "Endurance Builder",
    maintain_fitness: "Balanced Week",
  };

  const workouts = DAY_SPREAD[days].map((day, i) => {
    const slug = rotation[i % rotation.length];
    const hard = i % 3 === 2; // every third session pushes a little
    return {
      slug,
      day_of_week: day,
      duration_minutes: hard ? base + 10 : base,
      name: `${slug[0].toUpperCase()}${slug.slice(1)} ${hard ? "push" : "base"}`,
      descriptor: hard ? "Slightly harder effort — finish strong" : "Comfortable, repeatable effort",
    };
  });

  return {
    name: `${titles[goal.primary_goal] ?? "Balanced Week"} — ${weeks}-week plan`,
    description: personalised
      ? `Personalised for your ${exp} level and ${days}-day week. ` +
        `Repeats weekly for ${weeks} weeks toward your ${goal.primary_goal.replace(/_/g, " ")} goal.`
      : `A simple ${days}-day week toward your ${goal.primary_goal.replace(/_/g, " ")} goal. ` +
        `Repeats weekly for ${weeks} weeks. Upgrade for deeper personalisation.`,
    duration_weeks: weeks,
    workouts_per_week: days,
    model: "stub",
    strategy: personalised ? "personalised" : "basic",
    workouts,
  };
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
    );

    const { data: goal } = await supabase
      .from("fitness_goals")
      .select("primary_goal, weekly_commitment_days, timeline_weeks")
      .is("achieved_at", null)
      .maybeSingle();
    if (!goal) return json({ error: "no_active_goal" }, 400);

    const { data: profile } = await supabase
      .from("fitness_profiles")
      .select("activity_level, training_experience, preferred_workout_type_ids")
      .maybeSingle();

    const { data: me } = await supabase.from("profiles").select("role").maybeSingle();
    const personalised = me?.role === "premium" || me?.role === "expert";

    let preferredSlugs: string[] = [];
    const ids = profile?.preferred_workout_type_ids ?? [];
    if (ids.length > 0) {
      const { data: types } = await supabase.from("workout_types").select("slug").in("id", ids);
      preferredSlugs = (types ?? []).map((t: { slug: string }) => t.slug);
    }

    return json(buildStubPlan(goal as Goal, (profile ?? {
      activity_level: null, training_experience: null, preferred_workout_type_ids: [],
    }) as Profile, preferredSlugs, personalised));
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
