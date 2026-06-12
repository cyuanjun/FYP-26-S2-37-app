// SuggestPlan AI proxy — the second AI surface (build-plan §5).
//
// Serves BOTH tiers: Free = basic depth, Premium = personalised (role read
// server-side). Asks OpenAI (Gemini fallback) for the weekly schedule using a
// STRICT JSON schema, then validates/clamps every field server-side so the
// app always receives exactly the shape it renders:
//   { name, description, duration_weeks, workouts_per_week, model, strategy,
//     workouts: [{ slug, day_of_week, duration_minutes, name, descriptor }] }
// With no API key set (or any AI failure), falls back to the deterministic
// stub — same shape, so the app never changes.
//
// Secrets (Edge Function env): OPENAI_API_KEY, optional GEMINI_API_KEY.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const OPENAI_MODEL = "gpt-4o-mini";
const GEMINI_MODEL = "gemini-2.0-flash";

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
interface Slot {
  slug: string;
  day_of_week: number;
  duration_minutes: number;
  name: string;
  descriptor: string;
}

// Day spread for n workouts/week (1=Mon … 7=Sun).
const DAY_SPREAD: Record<number, number[]> = {
  1: [3], 2: [2, 5], 3: [1, 3, 5], 4: [1, 3, 5, 6],
  5: [1, 2, 4, 5, 6], 6: [1, 2, 3, 4, 5, 6], 7: [1, 2, 3, 4, 5, 6, 7],
};

const FILLERS: Record<string, string[]> = {
  lose_weight: ["running", "cycling", "hiit"],
  build_muscle: ["strength", "strength", "hiit"],
  improve_endurance: ["running", "cycling", "rowing"],
  maintain_fitness: ["running", "strength", "yoga"],
};

const TITLES: Record<string, string> = {
  lose_weight: "Lean & Consistent",
  build_muscle: "Progressive Strength",
  improve_endurance: "Endurance Builder",
  maintain_fitness: "Balanced Week",
};

function baseMinutes(exp: string): number {
  return exp === "advanced" ? 50 : exp === "intermediate" ? 40 : 30;
}

function buildStubPlan(goal: Goal, profile: Profile, preferredSlugs: string[], personalised: boolean) {
  const days = Math.min(Math.max(goal.weekly_commitment_days ?? 3, 1), 7);
  const weeks = goal.timeline_weeks ?? 4;
  const exp = profile.training_experience ?? "beginner";
  const base = baseMinutes(exp);
  const rotation = [...new Set([...preferredSlugs, ...(FILLERS[goal.primary_goal] ?? FILLERS.maintain_fitness)])];

  const workouts = DAY_SPREAD[days].map((day, i) => {
    const slug = rotation[i % rotation.length];
    const hard = i % 3 === 2;
    return {
      slug,
      day_of_week: day,
      duration_minutes: hard ? base + 10 : base,
      name: `${slug[0].toUpperCase()}${slug.slice(1)} ${hard ? "push" : "base"}`,
      descriptor: hard ? "Slightly harder effort — finish strong" : "Comfortable, repeatable effort",
    };
  });

  return {
    name: `${TITLES[goal.primary_goal] ?? "Balanced Week"} — ${weeks}-week plan`,
    description: personalised
      ? `Personalised for your ${exp} level and ${days}-day week. Repeats weekly for ${weeks} weeks toward your ${goal.primary_goal.replace(/_/g, " ")} goal.`
      : `A simple ${days}-day week toward your ${goal.primary_goal.replace(/_/g, " ")} goal. Repeats weekly for ${weeks} weeks. Upgrade for deeper personalisation.`,
    duration_weeks: weeks,
    workouts_per_week: days,
    model: "stub",
    strategy: personalised ? "personalised" : "basic",
    workouts,
  };
}

function planPrompt(
  goal: Goal, profile: Profile, preferredSlugs: string[], allowedSlugs: string[],
  days: number, weeks: number, personalised: boolean,
): string {
  const exp = profile.training_experience ?? "beginner";
  return [
    "You are a fitness coach generating ONE week of a repeating training plan.",
    `Goal: ${goal.primary_goal.replace(/_/g, " ")}. Experience: ${exp}. Plan length: ${weeks} weeks.`,
    `Exactly ${days} workouts on ${days} DISTINCT days (day_of_week: 1=Monday … 7=Sunday), sensibly spread (avoid back-to-back hard days).`,
    `Allowed workout slugs (use ONLY these): ${allowedSlugs.join(", ")}.`,
    preferredSlugs.length > 0
      ? `The user prefers: ${preferredSlugs.join(", ")} — feature them prominently.`
      : "No stated preferences - pick types that fit the goal.",
    `Durations around ${baseMinutes(exp)} minutes (15-120 allowed). Vary intensity across the week.`,
    personalised
      ? "PERSONALISED tier: tailor names/descriptors to the goal and experience; descriptors give a concrete focus cue."
      : "BASIC tier: keep names/descriptors simple and generic.",
    'Also produce a short plan "name" (catchy, ≤ 35 chars, no week count - we append it) and a 1-2 sentence "description".',
    "Workout names ≤ 25 chars; descriptors are ONE sentence. No medical advice. No markdown.",
  ].join("\n");
}

function planSchema(allowedSlugs: string[]) {
  return {
    type: "object",
    additionalProperties: false,
    required: ["name", "description", "workouts"],
    properties: {
      name: { type: "string" },
      description: { type: "string" },
      workouts: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: ["slug", "day_of_week", "duration_minutes", "name", "descriptor"],
          properties: {
            slug: { type: "string", enum: allowedSlugs },
            day_of_week: { type: "integer" },
            duration_minutes: { type: "integer" },
            name: { type: "string" },
            descriptor: { type: "string" },
          },
        },
      },
    },
  };
}

async function callOpenAI(prompt: string, schema: unknown, key: string): Promise<unknown> {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      messages: [{ role: "user", content: prompt }],
      max_tokens: 900,
      temperature: 0.6,
      response_format: {
        type: "json_schema",
        json_schema: { name: "weekly_plan", strict: true, schema },
      },
    }),
  });
  if (!res.ok) throw new Error(`openai ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const text = data.choices?.[0]?.message?.content;
  if (!text) throw new Error("openai: empty response");
  return JSON.parse(text);
}

async function callGemini(prompt: string, key: string): Promise<unknown> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${key}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{
          parts: [{
            text: prompt + '\n\nRespond with ONLY a JSON object: {"name": string, "description": string, "workouts": [{"slug": string, "day_of_week": int, "duration_minutes": int, "name": string, "descriptor": string}]}',
          }],
        }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.6 },
      }),
    },
  );
  if (!res.ok) throw new Error(`gemini ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error("gemini: empty response");
  return JSON.parse(text);
}

// Guarantees the shape/values the app renders, whatever the model returned.
function validatePlan(
  raw: unknown, allowedSlugs: string[], days: number, weeks: number,
  goal: Goal, profile: Profile, preferredSlugs: string[], personalised: boolean,
) {
  const obj = raw as Record<string, unknown>;
  const allowed = new Set(allowedSlugs);
  const seenDays = new Set<number>();
  const slots: Slot[] = [];

  for (const w of (Array.isArray(obj.workouts) ? obj.workouts : []) as Record<string, unknown>[]) {
    const slug = String(w.slug ?? "");
    const day = Math.round(Number(w.day_of_week ?? 0));
    if (!allowed.has(slug)) continue;
    if (day < 1 || day > 7 || seenDays.has(day)) continue;
    seenDays.add(day);
    slots.push({
      slug,
      day_of_week: day,
      duration_minutes: Math.min(Math.max(Math.round(Number(w.duration_minutes ?? 30)), 15), 120),
      name: String(w.name ?? slug).slice(0, 40) || slug,
      descriptor: String(w.descriptor ?? "").slice(0, 160),
    });
  }

  // Top up if the model under-delivered; trim if it over-delivered.
  const stub = buildStubPlan(goal, profile, preferredSlugs, personalised);
  for (const s of stub.workouts) {
    if (slots.length >= days) break;
    if (!seenDays.has(s.day_of_week)) {
      seenDays.add(s.day_of_week);
      slots.push(s);
    }
  }
  slots.sort((a, b) => a.day_of_week - b.day_of_week);
  const workouts = slots.slice(0, days);
  if (workouts.length === 0) throw new Error("ai plan had no usable workouts");

  const aiName = String(obj.name ?? "").trim().slice(0, 35);
  const aiDesc = String(obj.description ?? "").trim().slice(0, 280);

  return {
    name: `${aiName || (TITLES[goal.primary_goal] ?? "Balanced Week")} — ${weeks}-week plan`,
    description: aiDesc || stub.description,
    duration_weeks: weeks,
    workouts_per_week: workouts.length,
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

    // RLS returns stock types + the caller's own custom ones.
    const { data: types } = await supabase.from("workout_types").select("id, slug");
    const allTypes = types ?? [];
    const allowedSlugs = allTypes.map((t: { slug: string }) => t.slug);
    const prefIds = new Set(profile?.preferred_workout_type_ids ?? []);
    const preferredSlugs = allTypes
      .filter((t: { id: string }) => prefIds.has(t.id))
      .map((t: { slug: string }) => t.slug);

    const g = goal as Goal;
    const p = (profile ?? {
      activity_level: null, training_experience: null, preferred_workout_type_ids: [],
    }) as Profile;
    const days = Math.min(Math.max(g.weekly_commitment_days ?? 3, 1), 7);
    const weeks = g.timeline_weeks ?? 4;

    const prompt = planPrompt(g, p, preferredSlugs, allowedSlugs, days, weeks, personalised);
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    const geminiKey = Deno.env.get("GEMINI_API_KEY");

    if (openaiKey) {
      try {
        const raw = await callOpenAI(prompt, planSchema(allowedSlugs), openaiKey);
        const plan = validatePlan(raw, allowedSlugs, days, weeks, g, p, preferredSlugs, personalised);
        return json({ ...plan, model: OPENAI_MODEL });
      } catch (_) { /* fall through */ }
    }
    if (geminiKey) {
      try {
        const raw = await callGemini(prompt, geminiKey);
        const plan = validatePlan(raw, allowedSlugs, days, weeks, g, p, preferredSlugs, personalised);
        return json({ ...plan, model: GEMINI_MODEL });
      } catch (_) { /* fall through */ }
    }
    return json(buildStubPlan(g, p, preferredSlugs, personalised));
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
