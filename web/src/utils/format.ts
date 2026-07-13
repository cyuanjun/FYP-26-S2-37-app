export type GrowthClass = "up" | "down" | "neutral";

export function getGrowthClass(value: string): GrowthClass {
  const trimmed = String(value ?? "").trim();
  if (trimmed.startsWith("-")) return "down";
  if (trimmed.startsWith("+")) return "up";
  return "neutral";
}

export function formatGrowth(value: string): string {
  const growth = String(value ?? "0%").trim();
  if (growth.startsWith("-")) return `↓ ${growth}`;
  if (growth.startsWith("+")) return `↑ ${growth}`;
  return growth;
}

// A growth string is "notable" only when it's an actual signed percentage that
// changed. The flat "0%" and "new" (no prior baseline) cases are not worth
// surfacing as a badge — they confuse readers more than they inform.
export function isGrowthNotable(value: string): boolean {
  const v = String(value ?? "").trim();
  if (!v) return false;
  if (v.toLowerCase() === "new") return false;
  if (v === "0%" || v === "+0%" || v === "-0%") return false;
  return v.startsWith("+") || v.startsWith("-");
}

export function formatPrice(value: string): string {
  const price = String(value ?? "").trim();
  if (!price) return "";
  if (price.toLowerCase() === "varies") return "varies";
  if (price.toLowerCase().includes("quote") || price.toLowerCase().includes("add-on")) return price;
  if (price.startsWith("$")) return price;
  return `$${price}`;
}
