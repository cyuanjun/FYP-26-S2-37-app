import seedData from "./seed/landing-page.seed.json";
import metricSeed from "./seed/metrics.seed.json";
import pricingSeed from "./seed/pricing.seed.json";
import { supabase } from "./supabaseClient";

type MetricSource =
  | "free_users"
  | "premium_users"
  | "verified_experts"
  | "approved_reviews"
  | "active_categories"
  | "contact_resolved";

interface MetricBoundItem {
  data_source: MetricSource;
  segment_count?: string;
  metric_value?: string;
  growth_percentage: string;
}

interface GatewaySection {
  type: string;
  user_base?: MetricBoundItem[];
  items?: unknown[];
  activity_series?: ActivityWeek[];
}

interface GatewayLandingPage {
  sections: GatewaySection[];
}

type MetricSeed = Partial<Record<MetricSource, { value: string; growth_percentage: string }>>;

interface PricingItem {
  plan_name: string;
  price: string;
  description: string;
  button_text: string;
  button_url: string;
  features: string[];
}

interface PricingRow {
  plan_name: string;
  price_label: string;
  description: string;
  button_text: string;
  button_url: string;
  features: string[];
}

interface FaqItem {
  question: string;
  answer: string;
}

interface ActivityWeek {
  week_start: string;
  session_count: number;
  active_minutes: number;
}

const seedMetricValues = metricSeed as MetricSeed;

export async function readLandingSeed() {
  // Page structure (copy, section order, media placeholders) stays bundled;
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

/// landing_metric_summary() returns live counts; growth %s stay seed-side —
/// the database has no month-over-month history to derive them from.
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

/// FAQ entries live in landing_faqs; the seed section's items are the
/// offline fallback (null = fall back to whatever the seed carries).
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

/// Weekly platform activity (sessions + active minutes) straight from
/// workout_sessions via landing_activity_series() — null = chart placeholder.
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
