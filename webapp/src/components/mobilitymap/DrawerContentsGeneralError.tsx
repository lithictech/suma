import { AppError } from "../../modules/errors.ts";
import FormError from "../../ui/FormError.tsx";
import DrawerContents from "./DrawerContents.tsx";

export default function DrawerContentsGeneralError({ error }: { error: AppError }) {
  return (
    <DrawerContents>
      <FormError noSurface error={error} />
    </DrawerContents>
  );
}
