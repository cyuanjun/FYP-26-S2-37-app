import seedData from "./seed/landing-page.seed.json";
import metricSeed from "./seed/metrics.seed.json";
import pricingSeed from "./seed/pricing.seed.json";
import { supabase } from "./supabaseClient";

// (#) The metric keys the landing_metric_summary RPC can return a count for.
type MetricSource =
  | "free_users"
  | "premium_users"
  | "verified_experts"
  | "approved_reviews"
  | "active_categories"
  | "contact_resolved";

// (#) A stat card in the seed page bound to one metric source; its count/value
// gets filled in live at hydrate time.
interface MetricBoundItem {
  data_source: MetricSource;
  segment_count?: string;
  metric_value?: string;
  growth_percentage: string;
}

// (#) One section of the landing page (statistics, pricing, faq, etc.) as
// carried in the seed JSON.
interface GatewaySection {
  type: string;
  user_base?: MetricBoundItem[];
  items?: unknown[];
  activity_series?: ActivityWeek[];
}

// (#) The whole landing page: an ordered list of sections.
interface GatewayLandingPage {
  sections: GatewaySection[];
}

// (#) Seed-side metric values keyed by source (value plus its growth % blurb).
type MetricSeed = Partial<Record<MetricSource, { value: string; growth_percentage: string }>>;

// (#) A pricing plan as the UI wants it (price already labelled).
interface PricingItem {
  plan_name: string;
  price: string;
  description: string;
  button_text: string;
  button_url: string;
  features: string[];
}

// (#) A pricing plan as stored in landing_pricing_plans (raw price_label column).
interface PricingRow {
  plan_name: string;
  price_label: string;
  description: string;
  button_text: string;
  button_url: string;
  features: string[];
}

// (#) A single FAQ question/answer pair.
interface FaqItem {
  question: string;
  answer: string;
}

// (#) One week of platform activity for the stats chart.
interface ActivityWeek {
  week_start: string;
  session_count: number;
  active_minutes: number;
}

// (#) Bundled metric values used to seed the shape and as the offline fallback.
const seedMetricValues = metricSeed as MetricSeed;

// (#) Builds the full landing page: keeps the bundled copy/layout but folds in
// live metrics, pricing, FAQs and activity pulled from the database.
export async function readLandingSeed() {
  // (#) Page structure (copy, section order, media placeholders) stays bundled;
  // metric values, pricing plans, and FAQs come live from the shared database.
  const [metrics, pricing, faqs, activity] = await Promise.all([
    readLiveMetrics(),
    readPricingPlans(),
    readFaqs(),
    readActivitySeries(),
  ]);
  const page = structuredClone(seedData) as GatewayLandingPage;
  page.sections = page.sections.map((section) =>
    hydrateSection(section, metrics, pricing, faqs, activity),
  );
  return page;
}

// (#) landing_metric_summary() returns live counts; growth %s stay seed-side,
// since the database has no month-over-month history to derive them from.
async function readLiveMetrics(): Promise<MetricSeed> {
  try {
    const { data, error } = await supabase.rpc("landing_metric_summary");
    if (error) throw error;
    const counts = data as Record<MetricSource, number | string>;
    const live: MetricSeed = {};
    for (const key of Object.keys(seedMetricValues) as MetricSource[]) {
      const value = counts[key];
      if (value === undefined || value === null) continue;
      live[key] = {
        value: typeof value === "number" ? value.toLocaleString("en-US") : value,
        growth_percentage: seedMetricValues[key]?.growth_percentage ?? "0",
      };
    }
    return live;
  } catch {
    return seedMetricValues;
  }
}

// (#) Reads active landing_pricing_plans in display order and maps them to the
// UI shape; falls back to the pricing seed if the query is empty or fails.
async function readPricingPlans(): Promise<PricingItem[]> {
  try {
    const { data, error } = await supabase
      .from("landing_pricing_plans")
      .select("plan_name, price_label, description, button_text, button_url, features")
      .eq("is_active", true)
      .order("display_order");
    if (error) throw error;
    if (!data.length) throw new Error("no pricing rows");
    return (data as PricingRow[]).map((row) => ({
      plan_name: row.plan_name,
      price: row.price_label,
      description: row.description,
      button_text: row.button_text,
      button_url: row.button_url,
      features: row.features,
    }));
  } catch {
    return pricingSeed as PricingItem[];
  }
}

// (#) FAQ entries live in landing_faqs; the seed section's items are the
// offline fallback (null = fall back to whatever the seed carries).
async function readFaqs(): Promise<FaqItem[] | null> {
  try {
    const { data, error } = await supabase
      .from("landing_faqs")
      .select("question, answer")
      .eq("is_active", true)
      .order("display_order");
    if (error) throw error;
    if (!data.length) throw new Error("no faq rows");
    return data as FaqItem[];
  } catch {
    return null;
  }
}

// (#) Weekly platform activity (sessions + active minutes) straight from
// workout_sessions via landing_activity_series(); null = chart placeholder
// (used when every week is empty or the call fails).
async function readActivitySeries(): Promise<ActivityWeek[] | null> {
  try {
    const { data, error } = await supabase.rpc("landing_activity_series", { p_weeks: 12 });
    if (error) throw error;
    const series = data as ActivityWeek[];
    if (!series.some((w) => w.session_count > 0)) return null;
    return series;
  } catch {
    return null;
  }
}

// (#) Folds the live data into one section: fills stat cards with metric values
// and the activity series, swaps in live pricing, and replaces FAQs when present.
function hydrateSection(
  section: GatewaySection,
  metrics: MetricSeed,
  pricing: PricingItem[],
  faqs: FaqItem[] | null,
  activity: ActivityWeek[] | null,
): GatewaySection {
  if (section.type === "statistics") {
    return {
      ...section,
      activity_series: activity ?? undefined,
      user_base: section.user_base?.map((item) => ({
        ...item,
        segment_count: metrics[item.data_source]?.value ?? "0",
        growth_percentage: metrics[item.data_source]?.growth_percentage ?? "0",
      })),
      items: (section.items as MetricBoundItem[] | undefined)?.map((item) => ({
        ...item,
        metric_value: metrics[item.data_source]?.value ?? "0",
        growth_percentage: metrics[item.data_source]?.growth_percentage ?? "0",
      })),
    };
  }

  if (section.type === "pricing") {
    return {
      ...section,
      items: pricing,
    };
  }

  if (section.type === "faq" && faqs) {
    return {
      ...section,
      items: faqs,
    };
  }

  return section;
}
