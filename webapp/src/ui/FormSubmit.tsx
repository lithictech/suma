import { AppError } from "../modules/errors.ts";
import Button from "./Button.tsx";
import ButtonGroup from "./ButtonGroup.tsx";
import FormFeedback from "./FormFeedback.tsx";
import Stack from "./Stack.tsx";
import React from "react";

export interface FormSubmitProps {
  label: string;
  secondary?: string;
  error?: AppError | null;
  success?: React.ReactNode | null;
}
export default function FormSubmit({
  label,
  secondary,
  error,
  success,
}: FormSubmitProps) {
  return (
    <Stack col gap={3}>
      <FormFeedback error={error} success={success} />
      <ButtonGroup col bottom>
        <Button type="submit">{label}</Button>
        {secondary && <Button variant="outline">{secondary}</Button>}
      </ButtonGroup>
    </Stack>
  );
}
