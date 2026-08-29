import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import { vehicleIconForVendorService } from "../modules/mobilityIconLookup";
import { ThemeColor } from "../types/theme";
import Icon from "../ui/Icon.tsx";
import Stack from "../ui/Stack";
import Money from "../uir/Money";
import "./TripList.css";
import MapPinIcon from "@heroicons/react/24/outline/MapPinIcon";
import dayjs from "dayjs";
import React from "react";

interface TripDetailProps {
  trip: MobilityTrip;
}

export default function TripDetail({ trip }: TripDetailProps) {
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
    <>
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
      <Stack direction="vertical" gap={4} className="p-3">
        <h3>{t("trips.your_trip")}</h3>
        <StartEnd
          t={beganAt}
          address={beginAddress}
          label={t("trips.start")}
          iconColor="text"
        />
        <StartEnd
          t={endedAt}
          address={endAddress}
          label={t("trips.end")}
          iconColor="success"
        />
      </Stack>
      <div className="trips-week-divider" />
      <Stack direction="vertical" gap={3} className="p-3">
        <h3>{t("trips.payment")}</h3>
        {charge.lineItems.map(({ memo, amount }) => (
          <Stack key={memo} direction="horizontal" className="justify-content-between">
            <div>{memo}</div>
            <Money>{amount}</Money>
          </Stack>
        ))}
      </Stack>
    </>
  );
}

interface StartEndProps {
  t: string;
  address?: MobilityTripParsedAddress;
  label: React.ReactNode;
  iconColor: ThemeColor;
}

function StartEnd({ t, address, label, iconColor }: StartEndProps) {
  if (address) {
    return (
      <Stack row gap={2} center>
        <Icon size={20} icon={MapPinIcon} color={iconColor} />
        <Stack col className="flex-1">
          <Stack row className="justify-content-between">
            <div>{address.part1}</div>
            <div className="color-text-muted font-size-sm">{label}</div>{" "}
          </Stack>
          <Stack row className="justify-content-between">
            <div className="color-text-muted">{address.part2}</div>
            <div className="color-text-muted">{dayjs(t).format("LT")}</div>{" "}
          </Stack>
        </Stack>
      </Stack>
    );
  }

  return (
    <Stack row gap={2} center>
      <Icon size={20} icon={MapPinIcon} color={iconColor} />
      <Stack col className="flex-1">
        <div className="color-text-muted font-size-sm">{label}</div>{" "}
        <div className="color-text-muted">{dayjs(t).format("LT")}</div>{" "}
      </Stack>
    </Stack>
  );
}
