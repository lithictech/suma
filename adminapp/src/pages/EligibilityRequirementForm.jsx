import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import useMountEffect from "../shared/react/useMountEffect";
import EligibilityRequirementExpressionEditor from "./EligibilityRequirementExpressionEditor";
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Radio,
  RadioGroup,
  Stack,
} from "@mui/material";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function EligibilityRequirementForm({
  isCreate,
  resource,
  setField,
  clearField,
  setFieldFromInput,
  register,
  isBusy,
  onSubmit,
}) {
  const [searchParams] = useSearchParams();
  const searchProgramId = Number(searchParams.get("programId") || -1);
  const searchResourceId = Number(searchParams.get("resourceId") || -1);
  const searchResourceType = searchParams.get("resourceType");
  const [resourceType, setResourceType] = React.useState(
    resource.resourceType || searchResourceType || "program"
  );
  const fixedResource = searchResourceId > 0;

  useMountEffect(() => {
    if (searchParams.get("edit")) {
      return;
    }
    if (searchProgramId > 0) {
      setField("program", {
        id: searchProgramId,
        label: searchParams.get("programLabel"),
      });
    }
    if (searchResourceId > 0) {
      setField(searchResourceType, {
        id: searchResourceId,
        label: searchParams.get("resourceLabel"),
      });
    }
  }, [searchParams]);

  const handleResourceTypeChange = (e) => {
    setResourceType(e.target.value);
    clearField(resourceType);
  };

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
        <FormControl disabled={fixedResource}>
          <FormLabel>Resource Type</FormLabel>
          <RadioGroup value={resourceType} row onChange={handleResourceTypeChange}>
            <FormControlLabel value="program" control={<Radio />} label="Program" />
            <FormControlLabel
              value="payment_trigger"
              control={<Radio />}
              label="Payment Trigger"
            />
          </RadioGroup>
        </FormControl>
        {resourceType === "program" && (
          <AutocompleteSearch
            key="program"
            {...register("program")}
            label="Member"
            helperText="Modify the eligibility of which program?"
            value={resource.program?.label || ""}
            fullWidth
            search={api.searchPrograms}
            disabled={fixedResource}
            style={{ flex: 1 }}
            onValueSelect={(mem) => setField("program", mem)}
            onTextChange={() => clearField("program")}
          />
        )}
        {resourceType === "payment_trigger" && (
          <AutocompleteSearch
            key="trigger"
            {...register("paymentTrigger")}
            label="Payment Trigger"
            helperText="Modify the eligibility of which payment trigger?"
            value={resource.paymentTrigger?.label || ""}
            fullWidth
            disabled={fixedResource}
            search={api.searchPaymentTriggers}
            style={{ flex: 1 }}
            onValueSelect={(org) => setField("paymentTrigger", org)}
            onTextChange={() => clearField("paymentTrigger")}
          />
        )}
      </Stack>
      {!isCreate && (
        <EligibilityRequirementExpressionEditor
          expressionTokens={resource.expressionTokens}
          setExpression={(e) => setField("expression", e)}
          sx={{ mt: 1 }}
        />
      )}
    </FormLayout>
  );
}
