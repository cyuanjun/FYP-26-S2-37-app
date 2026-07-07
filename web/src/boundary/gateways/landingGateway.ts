import seedData from "./seed/landing-page.seed.json";
import metricSeed from "./seed/metrics.seed.json";
import pricingSeed from "./seed/pricing.seed.json";

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
}

interface GatewayLandingPage {
  sections: GatewaySection[];
}

type MetricSeed = Partial<Record<MetricSource, { value: string; growth_percentage: string }>>;

const metricValues = metricSeed as MetricSeed;
const pricingItems = pricingSeed;

export async function readLandingSeed() {
  const page = structuredClone(seedData) as GatewayLandingPage;
  page.sections = page.sections.map(hydrateSection);
  return page;
}

function hydrateSection(section: GatewaySection) {
  if (section.type === "statistics") {
    return {
      ...section,
      user_base: section.user_base?.map((item) => ({
        ...item,
        segment_count: metricValues[item.data_source]?.value ?? "0",
        growth_percentage: metricValues[item.data_source]?.growth_percentage ?? "0",
      })),
      items: (section.items as MetricBoundItem[] | undefined)?.map((item) => ({
        ...item,
        metric_value: metricValues[item.data_source]?.value ?? "0",
        growth_percentage: metricValues[item.data_source]?.growth_percentage ?? "0",
      })),
    };
  }

  if (section.type === "pricing") {
    return {
      ...section,
      items: pricingItems,
    };
  }

  return section;
}
