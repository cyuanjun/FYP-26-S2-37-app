// (#) A single link (label + destination) used in nav bars and the footer.
export interface NavItem {
  label: string;
  url: string;
}

// (#) Footer content: site name, copyright line and the list of footer links.
export interface FooterData {
  site_name: string;
  copyright_text: string;
  links: NavItem[];
}

// (#) Site-wide chrome shared by every page: branding, nav and footer.
export interface SiteData {
  site_name: string;
  brand_first_word: string; // (#) two words so the logo can colour them differently
  brand_second_word: string;
  logo_url: string;
  navigation: NavItem[];
  auth_actions: NavItem[]; // (#) login/register buttons in the header
  footer: FooterData;
}

// (#) Hero section at the top of the landing page.
export interface IntroSection {
  type: "intro"; // (#) discriminant used to pick the renderer for this section
  eyebrow: string;
  headline_primary: string;
  headline_accent: string;
  hero_media_url: string;
  hero_title: string;
  hero_description: string;
  primary_cta_text: string;
  primary_cta_url: string;
  secondary_cta_text: string;
  secondary_cta_url: string;
}

// (#) One feature card (icon + title + blurb) in the features grid.
export interface FeatureItem {
  icon_url: string;
  title: string;
  description: string;
}

// (#) The "features" section: heading copy plus the list of feature cards.
export interface FeaturesSection {
  type: "features";
  eyebrow: string;
  title: string;
  section_description: string;
  items: FeatureItem[];
}

// (#) Named live metrics a stat/segment can bind to (resolved from the DB).
export type MetricSource =
  | "free_users"
  | "premium_users"
  | "verified_experts"
  | "approved_reviews"
  | "active_categories"
  | "contact_resolved";

// (#) One slice of the user-base breakdown (e.g. free vs premium members).
export interface UserBaseSegment {
  segment_name: string;
  segment_description: string;
  data_source: MetricSource; // (#) which live metric fills segment_count
  segment_count: string; // (#) display string; may carry a seed placeholder
  growth_percentage: string;
}

// (#) A single headline statistic with its trend line styling.
export interface StatisticItem {
  metric_label: string;
  line_color: string; // (#) hex colour for this metric's chart line
  chart_data_summary: string; // (#) short text describing the trend
  data_source: MetricSource;
  metric_value: string;
  growth_percentage: string;
}

// (#) One week of aggregate activity used to draw the overview chart.
export interface ActivityWeek {
  week_start: string;
  session_count: number;
  active_minutes: number;
}

// (#) The stats section: headline metrics, user-base segments and the
// (#) optional weekly activity series behind the overview chart.
export interface StatisticsSection {
  type: "statistics";
  eyebrow: string;
  title: string;
  section_description: string;
  overview_chart_image_url: string; // (#) fallback image if the series is absent
  user_base: UserBaseSegment[];
  items: StatisticItem[];
  activity_series?: ActivityWeek[];
}

// (#) Public profile of a featured expert shown on the landing page.
export interface ExpertProfile {
  user_id: string;
  display_name: string;
  email: string;
  avatar_url: string | null;
  title: string;
  years_coaching: number;
  about: string;
  credentials: string[];
  specialties: string[];
  rating_avg: number;
  review_count: number;
  client_count: number;
  verification_status: "pending" | "verified" | "rejected";
}

// (#) The experts section: heading copy plus which experts to feature.
export interface ExpertsSection {
  type: "featuredExperts";
  eyebrow: string;
  title: string;
  section_description: string;
  featured_user_ids: string[]; // (#) ids resolved to ExpertProfile at render time
}

// (#) One pricing plan card (name, price, blurb, CTA and feature bullets).
export interface PricingItem {
  plan_name: string;
  price: string;
  description: string;
  button_text: string;
  button_url: string;
  features: string[];
}

// (#) The pricing section: heading copy plus the list of plan cards.
export interface PricingSection {
  type: "pricing";
  eyebrow: string;
  title: string;
  section_description: string;
  items: PricingItem[];
}

// (#) One row in the star-rating breakdown bar.
export interface RatingDistributionItem {
  label: string;
}

// (#) A user-submitted testimonial and its moderation state.
export interface TestimonialSubmission {
  id: string;
  rating: number;
  created_at: string;
  feedback_text: string;
  user_display_name: string;
  user_category: string; // (#) the reviewer's role/segment label
  status: "pending" | "approved" | "rejected";
  submitted_at: string;
  admin_reply: string | null;
  reviewed_at: string | null;
}

// (#) The testimonials section: rating summary and which reviews to feature.
export interface TestimonialsSection {
  type: "testimonials";
  eyebrow: string;
  title: string;
  section_description: string;
  overall_rating_label: string;
  review_count_template: string; // (#) copy with a placeholder for the count
  rating_distribution: RatingDistributionItem[];
  featured_ids: string[];
}

// (#) One call-to-action panel (member or expert variant).
export interface CtaItem {
  eyebrow: string;
  panel_variant: "member" | "expert"; // (#) selects the panel's styling
  title: string;
  description: string;
  button_text: string;
  button_url: string;
}

// (#) A row of side-by-side CTA panels.
export interface CtaRowSection {
  type: "ctaRow";
  items: CtaItem[];
}

// (#) A single question/answer pair in the FAQ list.
export interface FaqItem {
  question: string;
  answer: string;
}

// (#) The FAQ section: heading copy plus the question/answer list.
export interface FaqSectionData {
  type: "faq";
  eyebrow: string;
  title: string;
  section_description: string;
  items: FaqItem[];
}

// (#) The contact section: heading copy, form field placeholders and socials.
export interface ContactSectionData {
  type: "contactSection";
  eyebrow: string;
  contact_heading: string;
  contact_subheading: string;
  contact_description: string;
  name_placeholder: string;
  email_placeholder: string;
  message_placeholder: string;
  terms_label: string;
  button_text: string;
  social_links: string[];
}

// (#) Payload the contact form sends when a visitor submits a message.
export interface ContactMessageInput {
  submitter_name: string;
  submitter_email: string;
  message: string;
}

// (#) Union of every section kind; the `type` field tells them apart.
export type PageSection =
  | IntroSection
  | FeaturesSection
  | StatisticsSection
  | ExpertsSection
  | PricingSection
  | TestimonialsSection
  | CtaRowSection
  | FaqSectionData
  | ContactSectionData;

// (#) The whole landing page: shared site chrome plus the ordered sections.
export interface LandingPageData {
  site: SiteData;
  sections: PageSection[];
}
