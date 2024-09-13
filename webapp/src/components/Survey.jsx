import { t } from "../localization";
import merge from "lodash/merge";
import React from "react";
import { FormLabel } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";
import Stack from "react-bootstrap/Stack";

export default function Survey({ feature, onSubmit }) {
  let survey = [];
  const handleCheck = (questionKey, event) => {
    const newAnswerKey = event.target.id;
    if (event.target.checked) {
      const questionObj = survey.find((item) => item.questionKey === questionKey);
      if (!questionObj) {
        // Add first time answers
        survey.push({ questionKey: questionKey, answerKeys: [newAnswerKey] });
        return;
      }
      const newObj = questionObj.answerKeys.push(newAnswerKey);
      survey.map((obj) => (obj === questionObj ? merge(questionObj, newObj) : obj));
      return;
    }
    // Delete answer from question
    survey = survey.map((obj) => {
      if (obj.questionKey === questionKey) {
        obj.answerKeys = obj.answerKeys.filter((k) => k !== newAnswerKey);
      }
      return obj;
    });
  };

  const handleRadio = (questionKey, event) => {
    const questionObj = survey.find((item) => item.questionKey === questionKey);
    if (!questionObj) {
      survey.push({ questionKey: questionKey, answerKeys: [event.target.id] });
      return;
    }
    survey = survey.map((obj) => {
      if (obj.questionKey === questionKey) {
        obj.answerKeys = [event.target.id];
      }
      return obj;
    });
  };
  return (
    <Form noValidate onSubmit={(e) => onSubmit(e, survey)}>
      <Stack gap="3">
        {feature === "food" && (
          <Options
            questionKey="shop_for_food"
            optionKeys={shopForFoodOptionKeys}
            handleChange={handleCheck}
          />
        )}
        {feature === "utilities" && (
          <Options
            questionKey="household_utilities"
            optionKeys={householdUtilitiesOptionKeys}
            handleChange={handleCheck}
          />
        )}
        <Options
          questionKey="member_description"
          optionKeys={memberDescriptionOptionKeys}
          handleChange={handleRadio}
          radio
        />
        <Options
          questionKey="want_to_learn"
          optionKeys={wantToLearnOptionKeys}
          feature={feature}
          handleChange={handleCheck}
        />
      </Stack>
      <div className="button-stack mt-4">
        <Button type="submit" variant="outline-primary">
          {t("common:join_waitlist")}
        </Button>{" "}
      </div>
    </Form>
  );
}

function Options({ questionKey, optionKeys, feature, radio, handleChange }) {
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
          onChange={(event) => handleChange(questionKey, event)}
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
