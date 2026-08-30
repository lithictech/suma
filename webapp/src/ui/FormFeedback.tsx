import FormError, { FormErrorError } from "./FormError.tsx";

interface FormFeedbackProps {
  error?: FormErrorError;
  success?: FormErrorError;
}

export default function FormFeedback({ error, success }: FormFeedbackProps) {
  if (error) {
    return <FormError error={error} />;
  }
  if (success) {
    return <FormError error={<>{success}</>} variant="success" />;
  }
  return null;
}
