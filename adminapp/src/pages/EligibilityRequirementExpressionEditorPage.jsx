import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import EligibilityRequirementExpressionEditor from "./EligibilityRequirementExpressionEditor";
import React from "react";

export default function EligibilityRequirementExpressionEditorPage() {
  return (
    <ResourceEdit
      apiGet={api.getEligibilityRequirement}
      apiUpdate={api.updateEligibilityRequirement}
      Form={EditorForm}
    />
  );
}

function EditorForm({ resource, setField, isBusy, onSubmit }) {
  const setExpression = React.useCallback((e) => setField("expression", e), [setField]);

  return (
    <FormLayout
      title="Edit Eligibility Requirement Expression"
      subtitle="Eligibility requirements are logical expressions that control through what attributes
      a member can access resources (program, payment trigger, etc).
      A resource can have multiple rquirement expressions;
      satisfaction of any expression provides access."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <EligibilityRequirementExpressionEditor
        requirement={resource}
        expressionTokens={resource.expressionTokens}
        setExpression={setExpression}
        sx={{ mt: 1 }}
      />
    </FormLayout>
  );
}
