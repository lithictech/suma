import { t } from "../../localization";
import Button from "../../ui/Button";
import FormFeedback from "../../ui/FormFeedback";
import DrawerContents from "./DrawerContents";

interface PostTripProps {
  endTrip: MobilityTrip;
  onCloseTrip: () => void;
  error?: any;
}

export default function DrawerContentsPostTrip({
  endTrip,
  onCloseTrip,
  error,
}: PostTripProps) {
  const { charge, provider } = endTrip;
  const handleClose = () => onCloseTrip();
  return (
    <DrawerContents>
      {t("mobility.trip_ended", {
        vendor: provider.vendorName,
        totalCost: charge!.customerCost,
        discountAmount: charge!.savings,
      })}
      <FormFeedback feedback={error} />
      <Button size="sm" variant="outline" className="w-100" onClick={handleClose}>
        {t("common.close")}
      </Button>
    </DrawerContents>
  );
}
