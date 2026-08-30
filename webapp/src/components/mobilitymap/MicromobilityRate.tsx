import { t } from "../../localization";
import Chip from "../../ui/Chip.tsx";

export default function MicromobilityRate({ rate }: { rate: Rate | SimpleRate }) {
  let disc,
    badge = null;
  // MobilityMapProvider only carries a SimpleRate, which has no discount info;
  // the discount-related fields are only present on a full Rate.
  const fullRate = rate as Rate;
  if (fullRate.undiscountedRate) {
    disc = (
      <p className="mb-0">
        <s>
          {t("mobility.rate_micromobility", {
            surcharge: fullRate.undiscountedRate.surcharge,
            unitAmount: fullRate.undiscountedRate.unitAmount,
          })}
        </s>
      </p>
    );
    badge = <Chip variant="success">{fullRate.name}</Chip>;
  }
  return (
    <div className="d-flex flex-column gap-2">
      {disc}
      <p className="mb-0">
        {t("mobility.rate_micromobility", {
          surcharge: rate.surcharge,
          unitAmount: rate.unitAmount,
        })}
        {badge}
      </p>
    </div>
  );
}
