import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import { formatOrNull } from "../modules/dayConfig";
import RemoveIcon from "@mui/icons-material/Remove";
import { Divider, Stack, TextField } from "@mui/material";
import React from "react";

export default function MobilityTripForm({
  isCreate,
  resource,
  setField,
  setFieldFromInput,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create a Mobility Trip" : "Update Mobility Trip"}
      subtitle="Mobility trips are taken with synced vendor vehicles on the suma
      map or via the vendors application. Trip details are synced from our
      vendors services (like Lyft Biketown) into suma so members can view their
      ride receipts."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ResponsiveStack alignItems="center" divider={<RemoveIcon />}>
          <SafeDateTimePicker
            label="Trip Started"
            value={resource.beganAt}
            seconds={true}
            onChange={(v) => setField("beganAt", formatOrNull(v))}
          />
          <SafeDateTimePicker
            label="Trip Ended"
            value={resource.endedAt}
            seconds={true}
            onChange={(v) => setField("endedAt", formatOrNull(v))}
          />
        </ResponsiveStack>
        <Divider />
        <ResponsiveStack>
          <TextField
            name="beginLat"
            value={resource.beginLat || 0}
            inputProps={latInputProps}
            fullWidth
            type="number"
            label="Starting Latitude"
            onChange={setFieldFromInput}
          />
          <TextField
            name="beginLng"
            value={resource.beginLng || 0}
            inputProps={lngInputProps}
            fullWidth
            type="number"
            label="Starting Longitude"
            onChange={setFieldFromInput}
          />
        </ResponsiveStack>
        <Divider />
        <ResponsiveStack>
          <TextField
            name="endLat"
            value={resource.endLat || 0}
            inputProps={latInputProps}
            fullWidth
            type="number"
            label="Ending Latitude"
            onChange={setFieldFromInput}
          />
          <TextField
            name="endLng"
            value={resource.endLng || 0}
            inputProps={lngInputProps}
            fullWidth
            type="number"
            label="Ending Longitude"
            onChange={setFieldFromInput}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}

const MAX_LAT_DEGREES = 90;
const MIN_LAT_DEGREES = -90;
const MAX_LNG_DEGREES = 180;
const MIN_LNG_DEGREES = -180;
const PRECISION_FACTOR = 10000000;
const latInputProps = {
  step: 1 / PRECISION_FACTOR,
  max: MAX_LAT_DEGREES,
  min: MIN_LAT_DEGREES,
};
const lngInputProps = {
  step: 1 / PRECISION_FACTOR,
  max: MAX_LNG_DEGREES,
  min: MIN_LNG_DEGREES,
};
