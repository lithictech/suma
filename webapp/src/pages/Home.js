import sumaLogo from "../assets/images/suma-logo.png";
import RLink from "../components/RLink";
import { t } from "../localization";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

const Home = () => {
  return (
    <Container className="text-center">
      <img src={sumaLogo} alt="MySuma Logo" />
      <p>{t("common:welcome_to_suma")}</p>
      <div className="d-grid gap-3">
        <Button href="/start" variant="primary" as={RLink}>
          {t("forms:continue")}
        </Button>
        <SafeExternalLink
          component={Button}
          href="https://mysuma.org/"
          variant="outline-secondary"
          referrer
        >
          {t("common:learn_more")}
        </SafeExternalLink>
      </div>
    </Container>
  );
};

export default Home;
