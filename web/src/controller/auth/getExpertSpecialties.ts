import { readActiveExpertCategories } from "@/boundary/gateways/expertGateway";

export interface ExpertSpecialtyOption {
  value: string;
  label: string;
}

export async function getExpertSpecialties(): Promise<ExpertSpecialtyOption[]> {
  const categories = await readActiveExpertCategories();
  return categories.map((category) => ({
    value: category.id,
    label: category.label,
  }));
}
