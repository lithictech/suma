import transparencyIconTest from "../assets/images/privacy-policy-transparency-icon-cropped-test.png";
import TopNav from "../components/TopNav";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import clsx from "clsx";
import React from "react";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function PrivacyPolicy() {
  return (
    <div className="bg-light">
      <ScrollTopOnMount />
      <TopNav />
      <Container className="py-5">
        <Row>
          <Col md={8}>
            <h1 className="display-4">Overview</h1>
            <p className="fw-light">
              At suma, we believe you have the right to understand how your data is being
              used.
            </p>
            <p className="pt-2">
              <a href="#privacy-policy-title">
                <i>Click to jump to sumas privacy policy</i>
              </a>
            </p>
          </Col>
          <Col>
            <Stack gap={3}>
              <TabLink label="FAQ" to="/frequently-asked-questions" />
              <TabLink label="Contact Us" to="/contact-us" />
            </Stack>
          </Col>
        </Row>
        <Container
          className="border border-1 border-dark bg-white my-5 p-4"
          style={{ borderRadius: "25px" }}
        >
          <Row>
            <Col lg={4} className="px-lg-5 d-flex align-items-center">
              <h1 className="display-5">Community Driven</h1>
            </Col>
            <Col>
              Suma developed our privacy policy for and with and for community members.
              Our work started with students at the Ida B.Wells Just Data Lab where we
              explored best and worst privacy policy practices. From there, we wanted to
              hear what community had to say about our findings and engaged in
              conversations with community members across Portland. Their ideas, opinions,
              and thoughts have been incorpated in our policy at every level.
            </Col>
          </Row>
        </Container>
        <Row>
          <PedalCol
            heading="Transparency"
            paragraph="Suma collects minimal personal data from users with no hidden tricks in the fine print"
            img={transparencyIconTest}
          />
          <PedalCol
            heading="Consent"
            paragraph="Suma will asks for consent from our users and gives the option for users to change their mind"
            img={transparencyIconTest}
            right="true"
          />
        </Row>
        <Row className="mt-2">
          <PedalCol
            heading="Education"
            paragraph="Suma seeks keep our users in the know and explain how and why we need or use your data"
            img={transparencyIconTest}
          />
          <PedalCol
            heading="Trust"
            paragraph="Suma seeks to build trust with who we serve and overcome the privacy concerns preventing community from using tech"
            img={transparencyIconTest}
            right="true"
          />
        </Row>
      </Container>
      <hr />
      <Container className="py-5">
        <h1 id="privacy-policy-title" className="text-center display-4">
          Privacy Policy
        </h1>
      </Container>
    </div>
  );
}

const TabLink = ({ to, label }) => {
  return (
    <Link to={to} className="btn btn-outline-dark border-1">
      {label}
    </Link>
  );
};

const PedalCol = ({ heading, paragraph, img, right }) => {
  return (
    <Col lg={6} className={clsx("pt-4 pt-lg-1", !right && "text-lg-end")}>
      <Stack direction="horizontal" gap={3} className="align-items-start">
        <div className="mt-4">
          <h6>{heading}</h6>
          <p className="fw-light">{paragraph}</p>
        </div>
        <img src={img} alt="consent-icon" className={clsx(right && "order-first")} />
      </Stack>
    </Col>
  );
};
