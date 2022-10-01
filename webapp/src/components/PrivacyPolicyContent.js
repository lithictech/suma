import businessTransfer from "../assets/images/privacypolicy/business-transfer.svg";
import childrenUnder13 from "../assets/images/privacypolicy/children-under-13.svg";
import communication from "../assets/images/privacypolicy/communication.svg";
import cookiesPolicy from "../assets/images/privacypolicy/cookies-policy.svg";
import dataRemoval from "../assets/images/privacypolicy/data-removal.svg";
import dataRetention from "../assets/images/privacypolicy/data-retention.svg";
import disputeResolution from "../assets/images/privacypolicy/dispute-resolution.svg";
import methodsOfCollection from "../assets/images/privacypolicy/methods-of-collection.svg";
import methodsOfDataUsage from "../assets/images/privacypolicy/methods-of-data-usage.svg";
import consentIcon from "../assets/images/privacypolicy/overview-consent-icon.svg";
import educationIcon from "../assets/images/privacypolicy/overview-education-icon.svg";
import transparencyIcon from "../assets/images/privacypolicy/overview-transparency-icon.svg";
import trustIcon from "../assets/images/privacypolicy/overview-trust-icon.svg";
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
import Navbar from "react-bootstrap/Navbar";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Helmet } from "react-helmet-async";
import ReactMarkdown from "react-markdown";
import { Link } from "react-router-dom";

export default function PrivacyPolicyContent({ mobile }) {
  mobile = Boolean(mobile);
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  const PrivacyPolicySection = ({ id, title, p, img, list, subsection, children }) => {
    return (
      <div
        id={id}
        className={clsx(
          !subsection ? "privacy-policy-section-padding" : "pt-2",
          !mobile && !subsection && "mx-lg-5"
        )}
      >
        {!subsection ? (
          <h3 className="mb-4">{title}</h3>
        ) : (
          <h5 className="mt-3">{title}</h5>
        )}
        {img && (
          <img
            src={img}
            alt={title}
            className={clsx(
              "privacy-policy-image d-block mx-auto mb-4",
              !mobile && "float-md-end mx-md-4"
            )}
          />
        )}
        <p className="mb-4">{p}</p>
        {list && (
          <ul>
            {list.map((b, idx) => (
              <li key={idx + title} className="ps-3 pb-2">
                {b}
              </li>
            ))}
          </ul>
        )}
        {children}
      </div>
    );
  };

  React.useEffect(() => {
    // initialize isolated privacy policy translations
    Promise.delayOr(500, i18n.loadNamespaces("privacy-policy-strings")).then(() => {
      setI18NextLoading(false);
      // initialize top navigation BS scrollspy
      new ScrollSpy(document.body, {
        target: "#mobile-scrollspy",
        smoothScroll: true,
        rootMargin: "0px 0px -75%",
      });
      if (!mobile) {
        new ScrollSpy(document.body, {
          target: "#desktop-scrollspy",
          smoothScroll: true,
          rootMargin: "0px 0px -75%",
        });
      }
    });
  }, [mobile]);

  if (i18nextLoading) {
    return <ScreenLoader show />;
  }
  return (
    <div className="bg-light">
      <div
        className={clsx(
          "mx-auto",
          !mobile && "privacy-policy-desktop-container d-flex flex-column flex-xl-row"
        )}
      >
        <Helmet>
          <title>{`${t("privacy_policy:title")} | ${i18n.t(
            "strings:titles:suma_app"
          )}`}</title>
        </Helmet>
        {!mobile && (
          <Col className="table-of-contents-desktop d-none d-xl-block border-secondary border-end order-end">
            <TableOfContentsNav id="desktop-scrollspy" />
          </Col>
        )}
        <div className={clsx("sticky-top", !mobile && "container d-xl-none")}>
          <TableOfContentsNav id="mobile-scrollspy" mobile={true} />
        </div>
        <Container
          className={clsx("position-relative", !mobile && "privacy-policy-desktop")}
          tabIndex="0"
        >
          <Container id="overview" className={clsx(!mobile && "px-xl-3")}>
            <SpanishTranslatorButton />
            <Row>
              <Col xs={12} className={clsx(!mobile && "col-md-8")}>
                <h1 className="display-4">{t("overview:title")}</h1>
                <p className="fw-light">{t("overview:intro")}</p>
                <p className="pt-2">
                  <a href="#privacy-policy-title">
                    <i>{t("overview:jump_to_privacy_policy")}</i>
                  </a>
                </p>
              </Col>
              <Col xs={12} className={clsx("pt-3", !mobile && "col-md-4")}>
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
            <Container
              className={clsx(
                "community-driven-container-radius border border-1 border-dark bg-white my-5 p-4",
                !mobile && "px-lg-5"
              )}
            >
              <Row>
                <Col
                  xs={12}
                  className={clsx(!mobile && "col-lg-4 col-xl-5 align-self-lg-center")}
                >
                  <h1 className="display-5">{t("overview:community_driven_title")}</h1>
                </Col>
                <Col xs={12} className={clsx(!mobile && "col-lg-8 col-xl-7")}>
                  {t("overview:community_driven_intro")}
                </Col>
              </Row>
            </Container>
            <Row>
              <PedalCol
                mobile={mobile}
                heading={t("overview:transparency_title")}
                paragraph={t("overview:transparency_statement")}
                img={transparencyIcon}
              />
              <PedalCol
                mobile={mobile}
                heading={t("overview:consent_title")}
                paragraph={t("overview:consent_statement")}
                img={consentIcon}
                right={true}
              />
            </Row>
            <Row className="mt-2">
              <PedalCol
                mobile={mobile}
                heading={t("overview:education_title")}
                paragraph={t("overview:education_statement")}
                img={educationIcon}
              />
              <PedalCol
                mobile={mobile}
                heading={t("overview:trust_title")}
                paragraph={t("overview:trust_statement")}
                img={trustIcon}
                right={true}
              />
            </Row>
          </Container>
          <hr className="my-5" />
          <Container>
            <h1 id="privacy-policy-title" className="text-center display-4">
              {t("privacy_policy:title")}
            </h1>
            <p className="text-center mb-5">
              {t("privacy_policy:effective_date", { date: "09/01/2022" })}
            </p>
            <PrivacyPolicySection
              id="informationCollected"
              title={t("privacy_policy:information_collected:title")}
              p={t("privacy_policy:information_collected:paragraph")}
              list={[
                md("privacy_policy:information_collected:list:registration_md"),
                md("privacy_policy:information_collected:list:vendors_md"),
                md("privacy_policy:information_collected:list:subsidy_md"),
              ]}
            />
            <PrivacyPolicySection
              id="methodsOfCollection"
              title={t("privacy_policy:methods_of_collection:title")}
              p={t("privacy_policy:methods_of_collection:paragraph")}
              img={methodsOfCollection}
              list={[
                md("privacy_policy:methods_of_collection:list:registration_page_md"),
                md("privacy_policy:methods_of_collection:list:cookies_md"),
                md("privacy_policy:methods_of_collection:list:goods_and_services_md"),
                md("privacy_policy:methods_of_collection:list:community_partners_md"),
              ]}
            />
            <PrivacyPolicySection
              id="methodsOfDataUsage"
              title={t("privacy_policy:methods_of_data_usage:title")}
              p={t("privacy_policy:methods_of_data_usage:paragraph")}
              img={methodsOfDataUsage}
            >
              <PrivacyPolicySection
                subsection="true"
                title={t("privacy_policy_subsections:vendor_discounts:title")}
                p={t("privacy_policy_subsections:vendor_discounts:paragraph")}
              />
              <PrivacyPolicySection
                subsection="true"
                title={t("privacy_policy_subsections:third_party_subsidy:title")}
                p={t("privacy_policy_subsections:third_party_subsidy:paragraph")}
              />
              <PrivacyPolicySection
                subsection="true"
                title={t("privacy_policy_subsections:platform_usage:title")}
                p={t("privacy_policy_subsections:platform_usage:paragraph")}
              />
              <PrivacyPolicySection
                subsection="true"
                title={t("privacy_policy_subsections:educate_partners:title")}
                p={t("privacy_policy_subsections:educate_partners:paragraph")}
              />
              <PrivacyPolicySection
                subsection="true"
                title={t("privacy_policy_subsections:communicate_with_you:title")}
                p={t("privacy_policy_subsections:communicate_with_you:paragraph")}
              />
              <PrivacyPolicySection
                subsection="true"
                title={t(
                  "privacy_policy_subsections:security_and_fraud_prevention:title"
                )}
                p={t(
                  "privacy_policy_subsections:security_and_fraud_prevention:paragraph"
                )}
              />
              <PrivacyPolicySection
                subsection="true"
                title={t("privacy_policy_subsections:comply_with_law:title")}
                p={md("privacy_policy_subsections:comply_with_law:paragraph_md")}
              />
            </PrivacyPolicySection>
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
                title={t(
                  "privacy_policy_subsections:security_and_fraud_prevention:title"
                )}
                p={t(
                  "privacy_policy_subsections:security_and_fraud_prevention:paragraph"
                )}
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
                  t(
                    "privacy_policy_subsections:data_retention:list:maintain_performance"
                  ),
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
              img={childrenUnder13}
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
        </Container>
      </div>
    </div>
  );
}

const TableOfContentsNav = ({ id, mobile }) => {
  mobile = Boolean(mobile);
  const [expanded, setExpanded] = React.useState(!mobile || false);
  return (
    <Navbar
      className={clsx(
        "pt-0 pb-0 border-secondary",
        !mobile ? "sticky-top p-xl-4" : "border border-top-0"
      )}
      bg="light"
      variant="light"
      collapseOnSelect={mobile && true}
      expand={false}
      expanded={expanded}
      onToggle={() => setExpanded(!expanded)}
    >
      {mobile && (
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
      )}
      <Navbar.Collapse
        className={clsx("bg-light", mobile && "table-of-contents-collapse px-2")}
      >
        <Container id={id} className="position-relative">
          <Nav className="navbar-nav-scroll navbar-absolute">
            <Nav.Link href="#overview" className="active">
              {t("overview:title")}
            </Nav.Link>
            <hr />
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
  );
};

const TabLink = ({ to, label, title }) => {
  return (
    <Link to={to} className="btn btn-outline-dark border-1" title={title}>
      {label}
    </Link>
  );
};

const PedalCol = ({ heading, paragraph, img, right, mobile }) => {
  return (
    <Col xs={12} className={clsx("mb-4", !mobile && "mb-lg-0 px-sm-5 px-lg-2 col-lg-6")}>
      <Stack
        direction="horizontal"
        gap={3}
        className={clsx("align-items-start justify-content-center")}
      >
        <img
          src={img}
          alt={heading}
          className={clsx(right && "order-last", right && !mobile && "order-lg-last")}
        />
        <div
          className={clsx(
            "mt-4",
            !right && !mobile && "order-lg-first",
            right && !mobile && "order-lg-last"
          )}
        >
          <h5>{heading}</h5>
          <p className="fw-light">{paragraph}</p>
        </div>
      </Stack>
    </Col>
  );
};

const SpanishTranslatorButton = () => {
  const { language, changeLanguage } = useI18Next();
  return (
    <div className="d-flex justify-content-end">
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
