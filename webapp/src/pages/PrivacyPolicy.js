import transparencyIconTest from "../assets/images/privacy-policy-transparency-icon-cropped-test.png";
import businessTransfer from "../assets/images/privacypolicy/business-transfer.svg";
import communication from "../assets/images/privacypolicy/communication.svg";
import cookiesPolicy from "../assets/images/privacypolicy/cookies-policy.svg";
import dataRemoval from "../assets/images/privacypolicy/data-removal.svg";
import dataRetention from "../assets/images/privacypolicy/data-retention.svg";
import disputeResolution from "../assets/images/privacypolicy/dispute-resolution.svg";
import methodsOfCollection from "../assets/images/privacypolicy/methods-of-collection.svg";
import methodsOfDataUsage from "../assets/images/privacypolicy/methods-of-data-usage.svg";
import policyChanges from "../assets/images/privacypolicy/policy-changes.svg";
import thirdPartyAcceess from "../assets/images/privacypolicy/third-party-access.svg";
import "../assets/styles/privacy-policy.scss";
import ELink from "../components/ELink";
import ScreenLoader from "../components/ScreenLoader";
import useI18Next from "../localization/useI18Next";
import externalLinks from "../modules/externalLinks";
import ScrollSpy from "bootstrap/js/src/scrollspy";
import clsx from "clsx";
import i18n from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Nav from "react-bootstrap/Nav";
import NavDropdown from "react-bootstrap/NavDropdown";
import Navbar from "react-bootstrap/Navbar";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Helmet } from "react-helmet-async";
import ReactMarkdown from "react-markdown";
import { Link } from "react-router-dom";

export default function PrivacyPolicy() {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  const [expanded, setExpanded] = React.useState(false);
  const scrollSpyElement = document.getElementById("scrollspy");

  React.useEffect(() => {
    if (!scrollSpyElement) {
      return;
    }
    new ScrollSpy(document.body, { target: "#scrollspy", offset: 20 });
  }, [scrollSpyElement]);

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
        <title>{`${t("privacy_policy:title")} | ${i18n.t(
          "strings:titles:suma_app"
        )}`}</title>
      </Helmet>
      <Navbar
        className="pt-0 pb-0 border border-secondary border-top-0"
        bg="light"
        variant="light"
        sticky="top"
        collapseOnSelect={true}
        expand={false}
        expanded={expanded}
        onToggle={() => setExpanded(!expanded)}
      >
        <Container>
          <Navbar.Toggle className={clsx(expanded && "expanded")}>
            <div className="navbar-toggler-icon-bar bg-dark" />
            <div className="navbar-toggler-icon-bar bg-dark" />
            <div className="navbar-toggler-icon-bar bg-dark" />
          </Navbar.Toggle>
          <Navbar.Brand className="me-auto d-flex align-items-center">
            {t("common:table_of_contents")}
          </Navbar.Brand>
        </Container>
        <Navbar.Collapse className="table-of-contents-collapse">
          <Container id="scrollspy" className="position-relative">
            <Nav className="navbar-nav-scroll navbar-absolute">
              <Nav.Link href="#overview">{t("overview:title")}</Nav.Link>
              <NavDropdown.Divider />
              <Nav.Link href="#informationCollected">
                {t("privacy_policy:information_collected:title")}
              </Nav.Link>
              <Nav.Link href="#methodsOfCollection">
                {t("privacy_policy:methods_of_collection:title")}
              </Nav.Link>
              <Nav.Link href="#methodsOfDataUsage">
                {t("privacy_policy:methods_of_data_usage:title")}
              </Nav.Link>
              <Nav.Link href="#cookiesPolicy">
                {t("privacy_policy:cookies_policy:title")}
              </Nav.Link>
              <Nav.Link href="#thirdPartyAccess">
                {t("privacy_policy:third_party_access:title")}
              </Nav.Link>
              <Nav.Link href="#dataRetentionAndRemoval">
                {t("privacy_policy:data_retention_and_removal:title")}
              </Nav.Link>
              <Nav.Link href="#businessTransfer">
                {t("privacy_policy:business_transfer:title")}
              </Nav.Link>
              <Nav.Link href="#childrenUnder13">
                {t("privacy_policy:children_under_13:title")}
              </Nav.Link>
              <Nav.Link href="#communication">
                {t("privacy_policy:communication:title")}
              </Nav.Link>
              <Nav.Link href="#futureChangesToPolicy">
                {t("privacy_policy:future_changes_to_policy:title")}
              </Nav.Link>
              <Nav.Link href="#disputeResolution">
                {t("privacy_policy:dispute_resolution:title")}
              </Nav.Link>
              <Nav.Link href="#contactInformation">
                {t("privacy_policy:contact_information:title")}
              </Nav.Link>
            </Nav>
          </Container>
        </Navbar.Collapse>
      </Navbar>
      <Container className="position-relative" tabIndex="0">
        <SpanishTranslatorButton id="overview" />
        <Row>
          <Col xs={12}>
            <h1 className="display-4">{t("overview:title")}</h1>
            <p className="fw-light">{t("overview:intro")}</p>
            <p className="pt-2">
              <a href="#privacy-policy-title">
                <i>{t("overview:jump_to_privacy_policy")}</i>
              </a>
            </p>
          </Col>
          <Col xs={12}>
            <Stack gap={3}>
              <TabLink
                label={t("overview:faq:label")}
                title={t("overview:faq:title")}
                to="/frequently-asked-questions"
              />
              <TabLink
                label={t("overview:contact_us")}
                title={t("overview:contact_us")}
                to="/contact-us"
              />
            </Stack>
          </Col>
        </Row>
        <Container className="community-driven-container-radius border border-1 border-dark bg-white my-5 p-4">
          <Row>
            <Col xs={12} className="align-items-center">
              <h1 className="display-5">{t("overview:community_driven_title")}</h1>
            </Col>
            <Col xs={12}>{t("overview:community_driven_intro")}</Col>
          </Row>
        </Container>
        <Row>
          <PedalCol
            heading={t("overview:transparency_title")}
            paragraph={t("overview:transparency_statement")}
            img={transparencyIconTest}
          />
          <PedalCol
            heading={t("overview:consent_title")}
            paragraph={t("overview:consent_statement")}
            img={transparencyIconTest}
            right={true}
          />
        </Row>
        <Row className="mt-2">
          <PedalCol
            heading={t("overview:education_title")}
            paragraph={t("overview:education_statement")}
            img={transparencyIconTest}
          />
          <PedalCol
            heading={t("overview:trust_title")}
            paragraph={t("overview:trust_statement")}
            img={transparencyIconTest}
            right={true}
          />
        </Row>
        <hr className="mt-5" />
        <h1
          id="privacy-policy-title"
          className="privacy-policy-section-top-padding text-center display-4"
        >
          {t("privacy_policy:title")}
        </h1>
        <p className="text-center">
          {t("privacy_policy:effective_date", { date: "09/01/2022" })}
        </p>
        <PrivacyPolicySection
          id="informationCollected"
          title={t("privacy_policy:information_collected:title")}
          p={t("privacy_policy:information_collected:paragraph")}
          list={[
            t("privacy_policy:information_collected:list:registration"),
            t("privacy_policy:information_collected:list:vendors"),
            t("privacy_policy:information_collected:list:subsidy"),
          ]}
        />
        <PrivacyPolicySection
          id="methodsOfCollection"
          title={t("privacy_policy:methods_of_collection:title")}
          p={t("privacy_policy:methods_of_collection:paragraph")}
          img={methodsOfCollection}
          list={[
            t("privacy_policy:methods_of_collection:list:registration_page"),
            t("privacy_policy:methods_of_collection:list:cookies"),
            t("privacy_policy:methods_of_collection:list:goods_and_services"),
            t("privacy_policy:methods_of_collection:list:community_partners"),
          ]}
        />
        <PrivacyPolicySection
          id="methodsOfDataUsage"
          title={t("privacy_policy:methods_of_data_usage:title")}
          p={t("privacy_policy:methods_of_data_usage:paragraph")}
          img={methodsOfDataUsage}
          list={[
            t("privacy_policy:methods_of_data_usage:list:vendor_discounts"),
            t("privacy_policy:methods_of_data_usage:list:third_party_subsidy"),
            t("privacy_policy:methods_of_data_usage:list:platform_usage"),
            t("privacy_policy:methods_of_data_usage:list:educate_partners"),
            t("privacy_policy:methods_of_data_usage:list:communicate_with_you"),
            t("privacy_policy:methods_of_data_usage:list:security_and_fraud_prevention"),
            t("privacy_policy:methods_of_data_usage:list:comply_with_law"),
          ]}
        />
        <PrivacyPolicySection
          id="cookiesPolicy"
          title={t("privacy_policy:cookies_policy:title")}
          p={t("privacy_policy:cookies_policy:paragraph")}
          img={cookiesPolicy}
        >
          <p>{t("privacy_policy:cookies_policy:conclusion")}</p>
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="thirdPartyAccess"
          title={t("privacy_policy:third_party_access:title")}
          p={t("privacy_policy:third_party_access:paragraph")}
          img={thirdPartyAcceess}
        >
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:platform_vendors:title")}
            p={md("privacy_policy_subsections:platform_vendors:paragraph_md")}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:subsidy_providers:title")}
            p={t("privacy_policy_subsections:subsidy_providers:paragraph")}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:community_partners:title")}
            p={t("privacy_policy_subsections:community_partners:paragraph")}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:service_providers:title")}
            p={t("privacy_policy_subsections:service_providers:paragraph")}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:platform_dashboard:title")}
            p={t("privacy_policy_subsections:platform_dashboard:paragraph")}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:comply_with_law:title")}
            p={md("privacy_policy_subsections:comply_with_law:paragraph_md")}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:security_and_fraud_prevention:title")}
            p={t("privacy_policy_subsections:security_and_fraud_prevention:paragraph")}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:disputes:title")}
            p={t("privacy_policy_subsections:disputes:paragraph")}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:with_your_consent:title")}
            p={t("privacy_policy_subsections:with_your_consent:paragraph")}
          />
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="dataRetentionAndRemoval"
          title={t("privacy_policy:data_retention_and_removal:title")}
          p={t("privacy_policy:data_retention_and_removal:paragraph")}
        >
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:data_retention:title")}
            p={md("privacy_policy_subsections:data_retention:paragraph_md")}
            img={dataRetention}
            list={[
              t("privacy_policy_subsections:data_retention:list:maintain_performance"),
              t("privacy_policy_subsections:data_retention:list:qualifications"),
              t(
                "privacy_policy_subsections:data_retention:list:data_driven_business_decisions"
              ),
              t("privacy_policy_subsections:data_retention:list:legal_obligations"),
              t("privacy_policy_subsections:data_retention:list:resolving_disputes"),
            ]}
          />
          <PrivacyPolicySection
            subsection="true"
            title={t("privacy_policy_subsections:data_removal:title")}
            img={dataRemoval}
            p={t("privacy_policy_subsections:data_removal:paragraph")}
            list={[
              t("privacy_policy_subsections:data_removal:list:request_your_consent"),
              t("privacy_policy_subsections:data_removal:list:deleting_your_account"),
              t("privacy_policy_subsections:data_removal:list:deleting_certain_data"),
            ]}
          />
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="businessTransfer"
          title={t("privacy_policy:business_transfer:title")}
          p={md("privacy_policy:business_transfer:paragraph_md")}
          img={businessTransfer}
        >
          <p>{md("privacy_policy:business_transfer:conclusion_md")}</p>
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="childrenUnder13"
          title={t("privacy_policy:children_under_13:title")}
          p={t("privacy_policy:children_under_13:paragraph")}
        />
        <PrivacyPolicySection
          id="communication"
          title={t("privacy_policy:communication:title")}
          p={t("privacy_policy:communication:paragraph")}
          img={communication}
          list={[
            t("privacy_policy:communication:list:no_opt_out"),
            t("privacy_policy:communication:list:keep_valid_email"),
          ]}
        />
        <PrivacyPolicySection
          id="futureChangesToPolicy"
          title={t("privacy_policy:future_changes_to_policy:title")}
          p={md("privacy_policy:future_changes_to_policy:paragraph_md")}
          img={policyChanges}
        >
          <p>{md("privacy_policy:future_changes_to_policy:conclusion_md")}</p>
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="disputeResolution"
          title={t("privacy_policy:dispute_resolution:title")}
          p={md("privacy_policy:dispute_resolution:paragraph_md")}
          img={disputeResolution}
        />
        <PrivacyPolicySection
          id="contactInformation"
          title={t("privacy_policy:contact_information:title")}
          p={md("privacy_policy:contact_information:paragraph_md")}
        />
      </Container>
    </>
  );
}

const PrivacyPolicySection = ({ id, title, p, img, list, subsection, children }) => {
  return (
    <div
      id={id}
      className={clsx(!subsection ? "privacy-policy-section-top-padding" : "pt-3")}
    >
      {!subsection ? <h4>{title}</h4> : <h5 className="mt-3">{title}</h5>}
      {img && <img src={img} alt={title} className="d-block mx-auto" />}
      <p>{p}</p>
      {list && (
        <ul>
          {list.map((b) => (
            <li key={b}>{b}</li>
          ))}
        </ul>
      )}
      {children}
    </div>
  );
};

const TabLink = ({ to, label, title }) => {
  return (
    <Link to={to} className="btn btn-outline-dark border-1" title={title}>
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
        <img src={img} alt={heading} className={right && "order-first"} />
      </Stack>
    </Col>
  );
};

const SpanishTranslatorButton = ({ id }) => {
  const { language, changeLanguage } = useI18Next();
  return (
    <div id={id} className="d-flex justify-content-end">
      {language !== "en" ? (
        <Button
          variant="link"
          onClick={() => changeLanguage("en")}
          title={t("common:translate_to_english")}
        >
          <i>{t("common:in_english")}</i>
        </Button>
      ) : (
        <Button
          variant="link"
          onClick={() => changeLanguage("es")}
          title={t("common:translate_to_spanish")}
        >
          <i>{t("common:in_spanish")}</i>
        </Button>
      )}
    </div>
  );
};

const t = (key, options = {}) => {
  return i18n.t("privacy-policy-strings:" + key, options);
};

const md = (key, mdoptions = {}, i18noptions = {}) => {
  const MdLink = ({ node, ...rest }) => {
    return <ELink {...rest} />;
  };
  const str = t(key, { ...i18noptions, externalLinks });
  const components = { a: MdLink, p: React.Fragment, ...mdoptions.components };
  return <ReactMarkdown components={components}>{str}</ReactMarkdown>;
};