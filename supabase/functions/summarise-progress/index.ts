// SummariseProgress AI proxy — one of the two AI surfaces (build-plan §5).
//
// Computes the caller's weekly aggregates (RLS-scoped via their JWT), then asks
// OpenAI (Gemini fallback) to write a short summary of those REAL numbers.
// With no API key set, falls back to the deterministic stub — the response
// shape is identical in all three paths, so the app renders it unchanged:
//   { summary: string, model: string, range: "week", stats: {...} }
//
// Secrets (Edge Function env): OPENAI_API_KEY, optional GEMINI_API_KEY.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DAY_MS = 86_400_000;
const OPENAI_MODEL = "gpt-4o-mini";
const GEMINI_MODEL = "gemini-2.0-flash";

function startOfWeekUtc(d: Date): Date {
  const day = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const mondayOffset = (day.getUTCDay() + 6) % 7; // Mon = 0
  day.setUTCDate(day.getUTCDate() - mondayOffset);
  return day;
}

interface Row {
  ended_at: string;
  duration_seconds: number | null;
  distance_meters: number | null;
}

function aggregate(rows: Row[]) {
  const count = rows.length;
  const minutes = Math.round(rows.reduce((a, r) => a + (r.duration_seconds ?? 0), 0) / 60);
  const km = +(rows.reduce((a, r) => a + (r.distance_meters ?? 0), 0) / 1000).toFixed(1);
  return { count, minutes, km };
}

type Agg = ReturnType<typeof aggregate>;

function buildStubSummary(cur: Agg, prev: Agg): string {
  if (cur.count === 0) {
    return "No workouts logged this week yet. A short session today keeps your momentum going — even 20 minutes counts.";
  }
  const delta = prev.count === 0
    ? "Nice start to the week."
    : cur.count > prev.count
      ? `That's up from ${prev.count} last week — momentum is building.`
      : cur.count < prev.count
        ? `That's down from ${prev.count} last week — a good week to fit one more in.`
        : `Same as last week (${prev.count}) — steady consistency.`;
  const dist = cur.km > 0 ? ` You covered ${cur.km} km.` : "";
  const plural = cur.count === 1 ? "" : "s";
  return `This week you logged ${cur.count} workout${plural} (${cur.minutes} active min).${dist} ${delta}`;
}

function summaryPrompt(cur: Agg, prev: Agg, personalised: boolean, goal: string | null): string {
  return [
    "You are a friendly fitness companion. Write a SHORT progress summary (2-3 sentences, max 60 words)",
    "based ONLY on these real stats. Plain text, no markdown, no emoji, no headings.",
    "Never give medical advice. Be encouraging but honest about declines.",
    personalised && goal
      ? `The user's goal is: ${goal.replace(/_/g, " ")}. Relate the summary to that goal.`
      : "Keep it generic (basic tier) - do not invent goals or personal details.",
    `This week: ${cur.count} workouts, ${cur.minutes} active minutes, ${cur.km} km.`,
    `Last week: ${prev.count} workouts, ${prev.minutes} active minutes, ${prev.km} km.`,
  ].join("\n");
}

async function callOpenAI(prompt: string, key: string): Promise<string> {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      messages: [{ role: "user", content: prompt }],
      max_tokens: 160,
      temperature: 0.4,
    }),
  });
  if (!res.ok) throw new Error(`openai ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const text = data.choices?.[0]?.message?.content?.trim();
  if (!text) throw new Error("openai: empty response");
  return text;
}

async function callGemini(prompt: string, key: string): Promise<string> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${key}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    },
  );
  if (!res.ok) throw new Error(`gemini ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
  if (!text) throw new Error("gemini: empty response");
  return text;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing Authorization header" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return json({ error: "Unauthorized" }, 401);

  const now = new Date();
  const thisWeekStart = startOfWeekUtc(now);
  const lastWeekStart = new Date(thisWeekStart.getTime() - 7 * DAY_MS);

  // RLS limits this to the caller's own sessions.
  const { data, error } = await supabase
    .from("workout_sessions")
    .select("ended_at,duration_seconds,distance_meters")
    .not("ended_at", "is", null)
    .gte("ended_at", lastWeekStart.toISOString());

  if (error) return json({ error: error.message }, 500);

  const rows = (data ?? []) as Row[];
  const within = (r: Row, start: Date, end: Date) => {
    const t = new Date(r.ended_at);
    return t >= start && t < end;
  };
  const cur = aggregate(rows.filter((r) => within(r, thisWeekStart, new Date(thisWeekStart.getTime() + 7 * DAY_MS))));
  const prev = aggregate(rows.filter((r) => within(r, lastWeekStart, thisWeekStart)));

  // Premium summaries get goal context (basic stays generic).
  const { data: me } = await supabase.from("profiles").select("role").maybeSingle();
  const personalised = me?.role === "premium" || me?.role === "expert";
  let goal: string | null = null;
  if (personalised) {
    const { data: g } = await supabase
      .from("fitness_goals").select("primary_goal").is("achieved_at", null).maybeSingle();
    goal = g?.primary_goal ?? null;
  }

  const prompt = summaryPrompt(cur, prev, personalised, goal);
  const openaiKey = Deno.env.get("OPENAI_API_KEY");
  const geminiKey = Deno.env.get("GEMINI_API_KEY");

  let summary: string | null = null;
  let model = "stub";
  if (openaiKey) {
    try {
      summary = await callOpenAI(prompt, openaiKey);
      model = OPENAI_MODEL;
    } catch (_) { /* fall through to Gemini/stub */ }
  }
  if (summary === null && geminiKey) {
    try {
      summary = await callGemini(prompt, geminiKey);
      model = GEMINI_MODEL;
    } catch (_) { /* fall through to stub */ }
  }
  summary ??= buildStubSummary(cur, prev);

  return json({
    summary,
    model,
    range: "week",
    stats: { current: cur, previous: prev },
  });
});
