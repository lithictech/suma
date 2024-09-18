import utilitiesHeaderImage from "../assets/images/onboarding-utilities.jpg";
import FeaturePageHeader from "../components/FeaturePageHeader";
import WaitingList from "../components/WaitingList";
import { t } from "../localization";
import React from "react";

export default function Utilities() {
  return (
    <FeaturePageHeader imgSrc={utilitiesHeaderImage} imgAlt={t("utilities:page_title")}>
      <WaitingList
        title={t("utilities:page_title")}
        text={t("utilities:intro")}
        survey={surveySpec}
      />
    </FeaturePageHeader>
  );
}

const surveySpec = {
  topic: "utilities_waitlist",
  questions: [
    {
      key: "entity_type",
      labelKey: "surveys:member_type:label",
      format: "radio",
      answers: [
        { key: "community", labelKey: "surveys:member_type:community" },
        { key: "for_profit", labelKey: "surveys:member_type:for_profit" },
        { key: "government", labelKey: "surveys:member_type:government" },
        { key: "non_profit", labelKey: "surveys:member_type:non_profit" },
        { key: "philanthropy", labelKey: "surveys:member_type:philanthropy" },
      ],
    },
    {
      key: "utility_providers",
      labelKey: "surveys:utilities_options:label",
      format: "checkbox",
      answers: [
        { key: "centurylink", labelKey: "surveys:utilities_options:centurylink" },
        { key: "comcast", labelKey: "surveys:utilities_options:comcast" },
        { key: "frontier", labelKey: "surveys:utilities_options:frontier" },
        { key: "nw_natural", labelKey: "surveys:utilities_options:nw_natural" },
        { key: "pacific_power", labelKey: "surveys:utilities_options:pacific_power" },
        { key: "pge", labelKey: "surveys:utilities_options:pge" },
        { key: "verizon", labelKey: "surveys:utilities_options:verizon" },
      ],
    },
    {
      key: "learn_more",
      labelKey: "surveys:utilities_learn_more:label",
      format: "checkbox",
      answers: [
        {
          key: "connect_resources",
          labelKey: "surveys:utilities_learn_more:connect_resources",
        },
        {
          key: "grant_support",
          labelKey: "surveys:utilities_learn_more:grant_support",
        },
        { key: "partner", labelKey: "surveys:utilities_learn_more:partner" },
        { key: "save", labelKey: "surveys:utilities_learn_more:save" },
      ],
    },
  ],
};
