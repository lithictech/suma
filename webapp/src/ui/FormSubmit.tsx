import { FormErrorError } from "./FormError.tsx";

export interface FormSubmitProps {
  label: string;
  secondary?: string;
  error?: FormErrorError;
  success?: FormErrorError;
}
export default function FormSubmit({ label, secondary, error, success }) {}
