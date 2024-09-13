import api from "../api";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import { t } from "../localization";
import Survey from "./Survey";
import React from "react";
import Button from "react-bootstrap/Button";

export default function WaitingListPage({ feature, imgSrc, imgAlt, title, text }) {
  const [loading, setLoading] = React.useState(false);
  const [finished, setFinished] = React.useState(false);
  const handleSubmit = (e, surveyJson) => {
    setLoading(true);
    e.preventDefault();
    api.joinWaitlist({ feature, surveyJson }).finally(() => setFinished(true));
  };
  let content;
  if (finished) {
    content = (
      <div className="d-flex flex-column align-items-center">
        <div>
          <AnimatedCheckmark scale={2} />
        </div>
        <p className="mt-4 mb-0 text-center lead checkmark__text">
          {t("common:waitlisted")}
        </p>
        <div className="button-stack mt-4 w-100">
          <Button variant="outline-primary" href="/dashboard" as={RLink}>
            {t("common:go_home")}
          </Button>
        </div>
      </div>
    );
  } else if (loading) {
    content = <PageLoader buffered />;
  } else {
    content = (
      <>
        <h2>{title}</h2>
        {text}
        <Survey feature={feature} onSubmit={(e, survey) => handleSubmit(e, survey)} />
      </>
    );
  }
  return (
    <>
      <img src={imgSrc} alt={imgAlt} className="thin-header-image" />
      <LayoutContainer top gutters>
        {content}
      </LayoutContainer>
    </>
  );
}
