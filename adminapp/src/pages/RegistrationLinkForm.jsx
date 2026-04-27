import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import { dayjs, formatOrNull } from "../modules/dayConfig";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import { FormHelperText, FormLabel, Stack, TextField } from "@mui/material";
import React from "react";

export default function RegistrationLinkForm({
  isCreate,
  resource,
  setFieldFromInput,
  setField,
  clearField,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create a Registration Link" : "Update Registration Link"}
      subtitle="Users who sign up via a registration link become
      automatically verified members of an organization."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <AutocompleteSearch
          key="org"
          {...register("organization")}
          label="Organization"
          helperText="All members of the organization get the attribute."
          value={resource.organization?.label || ""}
          fullWidth
          disabled={!isCreate}
          search={api.searchOrganizations}
          style={{ flex: 1 }}
          onValueSelect={(org) => setField("organization", org)}
          onTextChange={() => clearField("organization")}
        />
        <FormLabel>Intro</FormLabel>
        <Stack spacing={2}>
          <MultiLingualText
            {...register("intro")}
            label="Intro"
            fullWidth
            value={resource.intro}
            required
            multiline
            onChange={(v) => setField("intro", v)}
          />
        </Stack>
        <FormLabel>Schedule</FormLabel>
        <FormHelperText>
          If a link has a schedule, it can only be used during times the schedule is
          active. The schedule is just like a calendar meeting; during the "meeting" the
          link can be used.
        </FormHelperText>
        <FormHelperText>
          Choose the begin and end times of the "meeting". If the meeting is recurring,
          build an RRULE (recurrence rule) using{" "}
          <SafeExternalLink href="https://icalendar.org/rrule-tool.html">
            https://icalendar.org/rrule-tool.html
          </SafeExternalLink>
          , then copy the RRULE into the text box below.
        </FormHelperText>
        <FormHelperText>
          Registration links without restrictions are always open.
        </FormHelperText>
        <SafeDateTimePicker
          label="Event Start"
          value={resource.icalDtstart || null}
          onChange={(v) => setField("icalDtstart", formatOrNull(v))}
        />
        <SafeDateTimePicker
          label="Event End"
          value={resource.icalDtend || null}
          onChange={(v) => setField("icalDtend", formatOrNull(v))}
        />
        <TextField
          {...register("icalRrule")}
          label="RRULE"
          name="icalRrule"
          value={resource.icalRrule}
          fullWidth
          helperText={
            <>
              Use{" "}
              <SafeExternalLink href="https://icalendar.org/rrule-tool.html">
                https://icalendar.org/rrule-tool.html
              </SafeExternalLink>{" "}
              to create an RRULE and then paste it here.
            </>
          }
          onChange={setFieldFromInput}
        />
        <div>
          Output:
          <br />
          <code>
            DTSTART:
            {resource.icalDtstart &&
              dayjs(resource.icalDtstart).format("YYYYMMDDHHmmss[Z]")}
            <br />
            DTEND:
            {resource.icalDtend && dayjs(resource.icalDtend).format("YYYYMMDDHHmmss[Z]")}
            <br />
            RRULE:{resource.icalRrule}
          </code>
        </div>
      </Stack>
    </FormLayout>
  );
}
