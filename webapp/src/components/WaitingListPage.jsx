import api from "../api";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import { t } from "../localization";
import React from "react";
import Button from "react-bootstrap/Button";

export default function WaitingListPage({ feature, imgSrc, imgAlt, title, text }) {
  const [loading, setLoading] = React.useState(false);
  const [finished, setFinished] = React.useState(false);
  const handleClick = (e) => {
    setLoading(true);
    e.preventDefault();
    api.joinWaitlist({ feature }).finally(() => setFinished(true));
  };
  let content;
  if (finished) {
    content = (
      <div className="d-flex flex-column align-items-center">
        <div>
          <AnimatedCheckmark scale={2} />
        </div>
        <p className="mt-4 mb-0 lead checkmark__text">{t("common:waitlisted")}</p>
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
        <div className="button-stack mt-4">
          <Button variant="outline-primary" onClick={handleClick}>
            {t("common:join_waitlist")}
          </Button>{" "}
        </div>
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
