import { t } from "../localization";
import { FeedbackValue } from "../modules/feedback.ts";
import { RoutePath } from "../routing/RoutePath.ts";
import BackButton from "./BackButton.tsx";
import Button, { ButtonProps } from "./Button.tsx";
import ButtonGroup from "./ButtonGroup.tsx";
import FormFeedback from "./FormFeedback.tsx";
import Stack from "./Stack.tsx";
import React from "react";

interface LabeledButtonProps extends ButtonProps {
  label?: string;
}

export interface FormSubmitProps {
  /** Label for the primary button. */
  label?: React.ReactNode;
  feedback?: FeedbackValue | null;
  back?: true | RoutePath;
  primary?: LabeledButtonProps;
  secondary?: LabeledButtonProps;
}

export default function FormSubmit({
  label,
  back,
  primary,
  secondary,
  feedback,
}: FormSubmitProps) {
  let sec = null;
  if (back === true) {
    sec = <BackButton variant="outline" />;
  } else if (back) {
    sec = <BackButton variant="outline" to={back} />;
  } else if (secondary) {
    sec = (
      <Button variant="outline" onClick={secondary.onClick}>
        {secondary.label || t("common.cancel")}
      </Button>
    );
  }
  primary = { children: label, type: "submit", ...primary };
  return (
    <Stack col gap={3} style={{ marginTop: "auto" }}>
      <FormFeedback feedback={feedback} />
      <ButtonGroup col bottom>
        <Button {...primary} />
        {sec}
      </ButtonGroup>
    </Stack>
  );
}
