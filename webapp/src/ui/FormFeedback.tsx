import { AppError } from "../modules/errors.ts";
import FormError from "./FormError.tsx";
import React from "react";

interface FormFeedbackProps {
  error?: AppError | null;
  success?: React.ReactNode | null;
}

export default function FormFeedback({ error, success }: FormFeedbackProps) {
  return (
    <>
      <FormError error={error} />
      {/* Wrap the success as an element so it is not interpreted as an error. */}
      <FormError error={<>{success}</>} variant="success" />
    </>
  );
}
