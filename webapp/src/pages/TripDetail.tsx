import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import { vehicleIconForVendorService } from "../modules/mobilityIconLookup";
import useUrlMarshal from "../state/useUrlMarshal";
import BreadcrumbBack from "../ui/BreadcrumbBack";
import Stack from "../ui/Stack";
import Money from "../uir/Money";
import dayjs from "dayjs";
import React from "react";

export default function TripDetail() {
  const { unmarshalFromUrl } = useUrlMarshal();
  let trip: MobilityTrip;
  try {
    trip = unmarshalFromUrl("trip", window.location.href) as MobilityTrip;
  } catch {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  const {
    vehicleType,
    provider,
    beganAt,
    beginAddress,
    endedAt,
    endAddress,
    charge,
    image,
  } = trip;

  return (
    <div>
      <LayoutContainer className="hstack">
        <BreadcrumbBack back="/trips">
          <h4 className="mb-0">{dayjs(beganAt).format("ll")}</h4>
        </BreadcrumbBack>
      </LayoutContainer>
      <Stack direction="vertical" gap={1} className="align-items-center p-3">
        <div style={{ height: 60 }}>
          <img
            src={vehicleIconForVendorService(vehicleType, provider.slug)}
            alt={`${provider.slug} ${vehicleType}`}
            className="trips-image-vehicle"
            height={60}
          />
        </div>
        <Money as="h4" className="mb-0">
          {charge.customerCost}
        </Money>
        <p className="mb-0">{t("trips.thanks")}</p>
      </Stack>
      {image ? (
        <SumaImage image={image} className="w-100" placeholderHeight={300} />
      ) : (
        <div className="trips-week-divider" />
      )}
      <Stack direction="vertical" gap={3} className="p-3">
        <h4>{t("trips.your_trip")}</h4>
        <StartEnd t={beganAt} address={beginAddress} label={t("trips.start")} />
        <StartEnd t={endedAt} address={endAddress} label={t("trips.end")} />
      </Stack>
      <div className="trips-week-divider" />
      <Stack direction="vertical" gap={3} className="p-3">
        <h4>{t("trips.payment")}</h4>
        {charge.lineItems.map(({ memo, amount }) => (
          <Stack key={memo} direction="horizontal" className="justify-content-between">
            <div>{memo}</div>
            <Money>{amount}</Money>
          </Stack>
        ))}
      </Stack>
    </div>
  );
}

interface StartEndProps {
  t: string;
  address?: MobilityTripParsedAddress;
  label: React.ReactNode;
}

function StartEnd({ t, address, label }: StartEndProps) {
  return (
    <Stack direction="horizontal" gap={2}>
      {address && (
        <Stack direction="vertical" gap={0.5}>
          <div>{address.part1}</div>
          <div className="small text-muted">{address.part2}</div>
        </Stack>
      )}
      <Stack direction="vertical" gap={0.5}>
        <div className="small text-muted text-end">{label}</div>{" "}
        <div className="small text-muted text-end">{dayjs(t).format("LT")}</div>{" "}
      </Stack>
    </Stack>
  );
}
