import sumaLogo from "../assets/images/suma-logo.png";
import SafeExternalLink from "../components/SafeExternalLink";
import i18next from "i18next";
import React from "react";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import { Link } from "react-router-dom";

const Home = () => {
  return (
    <div className="mainContainer">
      <Row>
        <Col className="text-center">
          <img src={sumaLogo} alt="MySuma Logo" />
          <p>{i18next.t("welcome_to_suma", { ns: "common" })}</p>
          <div className="d-grid gap-2">
            <SafeExternalLink
              href="https://mysuma.org/"
              variant="suma"
              className="text-white"
              referrer
            >
              Learn More
            </SafeExternalLink>
            <Link to="/start" className="btn btn-success">
              Continue
            </Link>
          </div>
        </Col>
      </Row>
    </div>
  );
};

export default Home;
