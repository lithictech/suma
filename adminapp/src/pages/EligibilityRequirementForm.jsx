import api from "../api";
import FormLayout from "../components/FormLayout";
import OneToManyEditor from "../components/OneToManyEditor";
import { Stack, Typography } from "@mui/material";
import React from "react";

export default function EligibilityRequirementForm({
  isCreate,
  resource,
  setField,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={
        isCreate ? "Create Eligibility Requirement" : "Update Eligibility Requirement"
      }
      subtitle="Eligibility requirements are logical expressions that control through what attributes
      a member can access resources (program, payment trigger, etc).
      A resource can have multiple rquirement expressions;
      satisfaction of any expression provides access."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <OneToManyEditor
          title="Program"
          items={resource.programs}
          setItems={(o) => setField("programs", o)}
          apiItemSearch={api.searchPrograms}
        />
        <OneToManyEditor
          title="Payment Trigger"
          items={resource.paymentTriggers}
          setItems={(o) => setField("paymentTriggers", o)}
          apiItemSearch={api.searchPaymentTriggers}
        />
      </Stack>
      <Typography sx={{ mt: 2 }}>
        {isCreate
          ? "You will be able to edit the expression after creating the requirement."
          : "You can edit the requirement formula from the detail page."}
      </Typography>
    </FormLayout>
  );
}
