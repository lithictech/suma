import { AppError } from "../../modules/feedback.ts";
import FormFeedback from "../../ui/FormFeedback.tsx";
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
      <FormFeedback noSurface feedback={error} />
    </DrawerContents>
  );
}
