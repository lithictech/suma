import { t } from "../localization";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { FormLabel } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";
import Stack from "react-bootstrap/Stack";

export default function Survey({ feature, onSubmit }) {
  let survey = {};
  const handleChange = (questionKey, newVal) => {
    if (isEmpty(newVal.answerKeys)) {
      delete survey[questionKey];
      return;
    }
    survey[questionKey] = newVal;
  };
  return (
    <Form noValidate onSubmit={(e) => onSubmit(e, survey)}>
      <Stack gap="3">
        {feature === "food" && (
          <Options
            questionKey="shop_for_food"
            optionKeys={shopForFoodOptionKeys}
            survey={survey}
            handleChange={(newValue) => handleChange("shop_for_food", newValue)}
          />
        )}
        {feature === "utilities" && (
          <Options
            questionKey="household_utilities"
            optionKeys={householdUtilitiesOptionKeys}
            survey={survey}
            handleChange={(newValue) => handleChange("household_utilities", newValue)}
          />
        )}
        <Options
          questionKey="member_description"
          optionKeys={memberDescriptionOptionKeys}
          survey={survey}
          handleChange={(newValue) => handleChange("member_description", newValue)}
          radio
        />
        <Options
          questionKey="want_to_learn"
          optionKeys={wantToLearnOptionKeys}
          survey={survey}
          handleChange={(newValue) => handleChange("want_to_learn", newValue)}
          feature={feature}
        />
      </Stack>
      <div className="button-stack mt-4">
        <Button type="submit" variant="outline-primary">
          {t("common:join_waitlist")}
        </Button>
      </div>
    </Form>
  );
}

function Options({ questionKey, optionKeys, survey, feature, radio, handleChange }) {
  function handleCheckboxChange(event) {
    if (event.target.checked) {
      handleChange({
        answerKeys: [event.target.id, ...(survey[questionKey]?.answerKeys || [])],
      });
      return;
    }
    const filteredKeys = survey[questionKey].answerKeys.filter(
      (k) => k !== event.target.id
    );
    handleChange({ answerKeys: filteredKeys });
  }
  function handleRadioChange(event) {
    handleChange({ answerKeys: [event.target.id] });
  }
  return (
    <div>
      <FormLabel>{t(`survey:${questionKey}:label`)}</FormLabel>
      {optionKeys.map((key) => (
        <Form.Check
          key={key}
          id={key}
          name={radio ? questionKey : key}
          label={t(`survey:${questionKey}:${key}`, {
            feature: t(feature + ":title").toLowerCase(),
          })}
          value={t(`survey:${questionKey}:${key}`, {
            feature: t(feature + ":title").toLowerCase(),
          })}
          type={radio ? "radio" : "checkbox"}
          onChange={(event) =>
            radio ? handleRadioChange(event) : handleCheckboxChange(event)
          }
        />
      ))}
    </div>
  );
}

const shopForFoodOptionKeys = ["fred_meyer", "safeway", "albertsons", "winco", "market"];
const wantToLearnOptionKeys = ["save", "connect_resources", "partner", "grant_support"];
const householdUtilitiesOptionKeys = [
  "pacific_power",
  "pge",
  "nw_natural",
  "comcast",
  "centurylink",
  "frontier",
  "verizon",
];
const memberDescriptionOptionKeys = [
  "community",
  "government",
  "non_profit",
  "philanthropy",
  "for_profit",
];
