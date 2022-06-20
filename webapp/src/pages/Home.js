import sumaLogo from "../assets/images/suma-logo.png";
import RLink from "../components/RLink";
import { t } from "../localization";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";

const Home = () => {
  return (
    <div className="main-container">
      <Row className="mt-3 mb-5">
        <Col className="text-center">
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
        </Col>
      </Row>
    </div>
  );
};

export default Home;
