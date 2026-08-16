import React from "react";

export interface HasFormFeedback {
  help?: React.ReactNode;
  error?: React.ReactNode;
}

interface FormFeedbackProps extends HasFormFeedback {
  inputId: string;
}

/**
 * Render the error, or form feedback if no error.
 */
export default function FormFeedback({ inputId, help, error }: FormFeedbackProps) {
  const describedBy = FormFeedback.idFor(inputId);
  if (error) {
    return (
      <div id={describedBy} className="form-text invalid-feedback" role="alert">
        {error}
      </div>
    );
  }
  if (help) {
    return (
      <div id={describedBy} className="form-text">
        {help}
      </div>
    );
  }
  return null;
}

FormFeedback.idFor = (inputId: string) => `${inputId}-feedback`;
