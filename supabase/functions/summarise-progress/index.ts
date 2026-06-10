// SummariseProgress AI proxy (STUB).
//
// Returns a deterministic, data-driven progress summary built from the caller's
// own workout history (RLS-scoped via their JWT). No API key needed. To go live,
// replace `buildStubSummary` with an OpenAI/Gemini call using the same `stats`
// payload — the app contract (AiGateway → this function) does not change.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DAY_MS = 86_400_000;

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

function buildStubSummary(cur: ReturnType<typeof aggregate>, prev: ReturnType<typeof aggregate>): string {
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

  return json({
    summary: buildStubSummary(cur, prev),
    model: "stub",
    range: "week",
    stats: { current: cur, previous: prev },
  });
});
