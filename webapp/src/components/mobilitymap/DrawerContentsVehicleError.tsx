import { AppError } from "../../modules/errors.ts";
import FormError from "../../ui/FormError.tsx";
import DrawerContents from "./DrawerContents.tsx";
import DrawerTitle from "./DrawerTitle.tsx";
import MicromobilityRate from "./MicromobilityRate.tsx";

export default function DrawerContentsVehicleError({
  error,
  provider,
}: {
  error: AppError;
  provider: MobilityMapProvider;
}) {
  return (
    <DrawerContents>
      <DrawerTitle>{provider.name}</DrawerTitle>
      <MicromobilityRate rate={provider.rate} />
      <FormError noSurface error={error} />
    </DrawerContents>
  );
}
