import { readActiveExpertCategories } from "@/boundary/gateways/expertGateway";

// (#) One choice for the specialty picker on the expert form: the id plus its display label.
export interface ExpertSpecialtyOption {
  value: string;
  label: string;
}

// (#) Loads the specialty options for the expert sign-up form. Reads the active expert
// categories from the expert gateway and reshapes each into a value/label option.
export async function getExpertSpecialties(): Promise<ExpertSpecialtyOption[]> {
  const categories = await readActiveExpertCategories();
  return categories.map((category) => ({
    value: category.id,
    label: category.label,
  }));
}
