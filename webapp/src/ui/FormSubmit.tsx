import { FeedbackValue } from "../modules/feedback.ts";

import Button from "./Button.tsx";
import ButtonGroup from "./ButtonGroup.tsx";
import FormFeedback from "./FormFeedback.tsx";
import Stack from "./Stack.tsx";

export interface FormSubmitProps {
  label: string;
  secondary?: string;
  feedback?: FeedbackValue | null;
}
export default function FormSubmit({ label, secondary, feedback }: FormSubmitProps) {
  return (
    <Stack col gap={3} style={{ marginTop: "auto" }}>
      <FormFeedback feedback={feedback} />
      <ButtonGroup col bottom>
        <Button type="submit">{label}</Button>
        {secondary && <Button variant="outline">{secondary}</Button>}
      </ButtonGroup>
    </Stack>
  );
}
