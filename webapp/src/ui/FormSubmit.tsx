import { t } from "../localization";
import { FeedbackValue } from "../modules/feedback.ts";
import { RoutePath } from "../routing/RoutePath.ts";
import BackButton from "./BackButton.tsx";
import Button from "./Button.tsx";
import ButtonGroup from "./ButtonGroup.tsx";
import FormFeedback from "./FormFeedback.tsx";
import Stack from "./Stack.tsx";
import React, { MouseEventHandler } from "react";

interface SecondaryProps {
  label?: string;
  onClick: MouseEventHandler;
}

interface AllFormSubmitProps {
  /** Label for the primary button. */
  label: React.ReactNode;
  feedback?: FeedbackValue | null;
  back: true | RoutePath;
  secondary: SecondaryProps;
}

export type FormSubmitProps = RequireOnlyOne<AllFormSubmitProps, "back" | "secondary">;

export default function FormSubmit({
  label,
  back,
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
  return (
    <Stack col gap={3} style={{ marginTop: "auto" }}>
      <FormFeedback feedback={feedback} />
      <ButtonGroup col bottom>
        <Button type="submit">{label}</Button>
        {sec}
      </ButtonGroup>
    </Stack>
  );
}
