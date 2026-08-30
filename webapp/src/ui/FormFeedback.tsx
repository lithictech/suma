import { FeedbackValue, Success } from "../modules/feedback.ts";
import "./FormFeedback.css";
import clsx from "clsx";
import React from "react";

type FormFeedbackVariant = "success" | "danger";

interface FormFeedbackProps {
  feedback: FeedbackValue | null | undefined;
  noSurface?: boolean;
  className?: string;
  style?: React.CSSProperties;
}

const FormFeedback = React.forwardRef<HTMLElement, FormFeedbackProps>(function (
  { feedback, noSurface, className, style }: FormFeedbackProps,
  ref
) {
  const isSuccess = feedback instanceof Success;
  const [variant, setVariant] = React.useState<FormFeedbackVariant>(
    isSuccess ? "success" : "danger"
  );
  React.useEffect(() => {
    if (!feedback) {
      return;
    }
    setVariant(isSuccess ? "success" : "danger");
  }, [feedback, isSuccess]);

  const sty = { ...style, color: `var(--color-${variant})` };
  if (!noSurface) {
    sty.backgroundColor = `var(--tint-${variant})`;
  }
  const msg = isSuccess ? feedback.value : feedback?.render();
  const cls = clsx(
    "form-feedback",
    !noSurface && "form-feedback-surface",
    !feedback && "form-feedback-hidden",
    className
  );
  return (
    <p
      ref={ref as React.ForwardedRef<HTMLParagraphElement>}
      className={cls}
      style={sty}
      role="alert"
    >
      {msg}
    </p>
  );
});

export default FormFeedback;
