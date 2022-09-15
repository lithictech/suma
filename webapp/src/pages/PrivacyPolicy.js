import transparencyIconTest from "../assets/images/privacy-policy-transparency-icon-cropped-test.png";
import ScreenLoader from "../components/ScreenLoader";
import useI18Next from "../localization/useI18Next";
import clsx from "clsx";
import i18n from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Helmet } from "react-helmet-async";
import { Link } from "react-router-dom";

export default function PrivacyPolicy() {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);

  const t = (key, options = {}) => {
    return i18n.t("privacy-policy-strings:" + key, options);
  };

  React.useEffect(() => {
    // initialize isolated privacy policy translations
    Promise.delayOr(500, i18n.loadNamespaces("privacy-policy-strings")).then(() => {
      setI18NextLoading(false);
    });
  }, []);

  if (i18nextLoading) {
    return <ScreenLoader show />;
  }
  return (
    <>
      <Helmet>
        <title>{`${t("title")} | ${i18n.t("strings:titles:suma_app")}`}</title>
      </Helmet>
      <Container>
        <SpanishTranslatorButton />
        <Row>
          <Col xs={12}>
            <h1 className="display-4">{t("overview")}</h1>
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
          <Col xs={12}>
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
            <Col xs={12} className="align-items-center">
              <h1 className="display-5">Community Driven</h1>
            </Col>
            <Col xs={12}>
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
        <hr className="my-5" />
        <h1 id="privacy-policy-title" className="text-center display-4">
          Privacy Policy
        </h1>
      </Container>
    </>
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
    <Col>
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

function SpanishTranslatorButton() {
  const { language, changeLanguage } = useI18Next();
  return (
    <div className="d-flex justify-content-end">
      {language !== "en" ? (
        <Button variant="link" onClick={() => changeLanguage("en")}>
          <i>English</i>
        </Button>
      ) : (
        <Button variant="link" onClick={() => changeLanguage("es")}>
          <i>En Español</i>
        </Button>
      )}
    </div>
  );
}
