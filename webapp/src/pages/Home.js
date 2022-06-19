import sumaLogo from "../assets/images/suma-logo.png";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import { Link } from "react-router-dom";

const Home = () => {
  return (
    <div className="main-container">
      <Row>
        <Col className="text-center">
          <img src={sumaLogo} alt="MySuma Logo" />
          <p>{i18next.t("common:welcome_to_suma")}</p>
          <div className="d-grid gap-2">
            <SafeExternalLink
              component={Button}
              href="https://mysuma.org/"
              variant="primary"
              referrer
            >
              {i18next.t("common:learn_more")}
            </SafeExternalLink>
            <Link to="/start" className="btn btn-success">
              {i18next.t("forms:continue")}
            </Link>
          </div>
        </Col>
      </Row>
    </div>
  );
};

export default Home;
