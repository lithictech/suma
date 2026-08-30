import React from "react";

export interface HasInputFeedback {
  help?: React.ReactNode;
  error?: React.ReactNode;
}

interface InputFeedbackProps extends HasInputFeedback {
  inputId: string;
}

/**
 * Render the error, or form feedback if no error.
 */
export default function InputFeedback({ inputId, help, error }: InputFeedbackProps) {
  const describedBy = InputFeedback.idFor(inputId);
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

InputFeedback.idFor = (inputId: string) => `${inputId}-feedback`;
