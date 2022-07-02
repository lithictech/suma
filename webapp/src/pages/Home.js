import sumaLogo from "../assets/images/suma-logo.png";
import RLink from "../components/RLink";
import { t } from "../localization";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";

const Home = () => {
  return (
    <Container className="text-center">
      <img src={sumaLogo} alt="MySuma Logo" className="p-4" style={{ width: 250 }} />
      <h1 className="mb-4">{t("common:welcome_to_suma")}</h1>
      <div className="button-stack">
        <Button href="/start" variant="outline-primary" as={RLink} className="w-75">
          {t("forms:continue")}
        </Button>
        <SafeExternalLink
          component={Button}
          href="https://mysuma.org/"
          variant="outline-secondary"
          referrer
          className="w-75 mt-3 nowrap"
        >
          {t("common:learn_more")}
        </SafeExternalLink>
      </div>
    </Container>
  );
};

export default Home;
