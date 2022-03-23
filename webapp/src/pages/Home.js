import sumaLogo from "../assets/images/suma-logo.png";
import SafeExternalLink from "../components/SafeExternalLink";
import React from "react";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";

const Home = () => {
  const { t } = useTranslation();

  return (
    <Container>
      <Row className="justify-content-center">
        <Col>
          <img src={sumaLogo} alt="MySuma Logo" />
          <p>{t("welcome to suma")}</p>
          <div className="d-grid gap-2">
            <SafeExternalLink
              href="https://mysuma.org/"
              variant="outline-primary"
              referrer
            >
              Learn More
            </SafeExternalLink>
            <Link to="/start" className="btn btn-outline-success">
              Continue
            </Link>
          </div>
        </Col>
      </Row>
    </Container>
  );
};

export default Home;
