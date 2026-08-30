import { AppError } from "../../modules/feedback.ts";
import FormFeedback from "../../ui/FormFeedback.tsx";
import DrawerContents from "./DrawerContents.tsx";

export default function DrawerContentsGeneralError({ error }: { error: AppError }) {
  return (
    <DrawerContents>
      <FormFeedback noSurface feedback={error} />
    </DrawerContents>
  );
}
