export interface NavItem {
  label: string;
  url: string;
}

export interface FooterData {
  site_name: string;
  copyright_text: string;
  links: NavItem[];
}

export interface SiteData {
  site_name: string;
  brand_first_word: string;
  brand_second_word: string;
  logo_url: string;
  navigation: NavItem[];
  auth_actions: NavItem[];
  footer: FooterData;
}

export interface IntroSection {
  type: "intro";
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

export interface FeatureItem {
  icon_url: string;
  title: string;
  description: string;
}

export interface FeaturesSection {
  type: "features";
  eyebrow: string;
  title: string;
  section_description: string;
  items: FeatureItem[];
}

export type MetricSource =
  | "free_users"
  | "premium_users"
  | "verified_experts"
  | "approved_reviews"
  | "active_categories"
  | "contact_resolved";

export interface UserBaseSegment {
  segment_name: string;
  segment_description: string;
  data_source: MetricSource;
  segment_count: string;
  growth_percentage: string;
}

export interface StatisticItem {
  metric_label: string;
  line_color: string;
  chart_data_summary: string;
  data_source: MetricSource;
  metric_value: string;
  growth_percentage: string;
}

export interface StatisticsSection {
  type: "statistics";
  eyebrow: string;
  title: string;
  section_description: string;
  overview_chart_image_url: string;
  user_base: UserBaseSegment[];
  items: StatisticItem[];
}

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

export interface ExpertsSection {
  type: "featuredExperts";
  eyebrow: string;
  title: string;
  section_description: string;
  featured_user_ids: string[];
}

export interface PricingItem {
  plan_name: string;
  price: string;
  description: string;
  button_text: string;
  button_url: string;
  features: string[];
}

export interface PricingSection {
  type: "pricing";
  eyebrow: string;
  title: string;
  section_description: string;
  items: PricingItem[];
}

export interface RatingDistributionItem {
  label: string;
}

export interface TestimonialSubmission {
  id: string;
  rating: number;
  created_at: string;
  feedback_text: string;
  user_display_name: string;
  user_category: string;
  status: "pending" | "approved" | "rejected";
  submitted_at: string;
  admin_reply: string | null;
  reviewed_at: string | null;
}

export interface TestimonialsSection {
  type: "testimonials";
  eyebrow: string;
  title: string;
  section_description: string;
  overall_rating_label: string;
  review_count_template: string;
  rating_distribution: RatingDistributionItem[];
  featured_ids: string[];
}

export interface CtaItem {
  eyebrow: string;
  panel_variant: "member" | "expert";
  title: string;
  description: string;
  button_text: string;
  button_url: string;
}

export interface CtaRowSection {
  type: "ctaRow";
  items: CtaItem[];
}

export interface FaqItem {
  question: string;
  answer: string;
}

export interface FaqSectionData {
  type: "faq";
  eyebrow: string;
  title: string;
  section_description: string;
  items: FaqItem[];
}

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

export interface ContactMessageInput {
  submitter_name: string;
  submitter_email: string;
  message: string;
}

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

export interface LandingPageData {
  site: SiteData;
  sections: PageSection[];
}
