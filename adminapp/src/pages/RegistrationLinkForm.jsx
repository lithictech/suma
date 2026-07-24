import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import {
  icalRruleState,
  parseIcalRrule,
  renderRruleState,
} from "../components/IcalEventEditor/icalconstants";
import IcalEventEditor from "../components/IcalEventEditor/index.jsx";
import MultiLingualText from "../components/MultiLingualText";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import { CardContent, Card, FormHelperText, FormLabel, Stack } from "@mui/material";
import React from "react";

export default function RegistrationLinkForm({
  isCreate,
  resource,
  setField,
  clearField,
  register,
  isBusy,
  onSubmit,
}) {
  const parsedRrule = parseIcalRrule(resource.icalRrule);
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
        <Card>
          <CardContent>
            <FormLabel>Schedule</FormLabel>
            <FormHelperText>
              If a link has a schedule, it can only be used during times the schedule is
              active. The schedule is just like a calendar meeting; during the "meeting"
              the link can be used.
            </FormHelperText>
            <FormHelperText>
              Choose the begin and end times of the "meeting". If the meeting is
              recurring, build an RRULE (recurrence rule) using{" "}
              <SafeExternalLink href="https://icalendar.org/rrule-tool.html">
                https://icalendar.org/rrule-tool.html
              </SafeExternalLink>
              , then copy the RRULE into the text box below.
            </FormHelperText>
            <FormHelperText>
              Registration links without restrictions are always open.
            </FormHelperText>
            <IcalEventEditor
              start={resource.icalDtstart}
              end={resource.icalDtend}
              rrule={{ ...icalRruleState(), ...parsedRrule }}
              onChange={(f, val) => {
                if (f === "start") {
                  setField("icalDtstart", val);
                } else if (f === "end") {
                  setField("icalDtend", val);
                } else {
                  setField("icalRrule", renderRruleState({ ...parsedRrule, ...val }));
                }
              }}
            />
          </CardContent>
        </Card>
      </Stack>
    </FormLayout>
  );
}
