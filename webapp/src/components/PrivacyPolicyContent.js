import businessTransfer from "../assets/images/privacypolicy/business-transfer.svg";
import childrenUnder13 from "../assets/images/privacypolicy/children-under-13.svg";
import communication from "../assets/images/privacypolicy/communication.svg";
import cookiesPolicy from "../assets/images/privacypolicy/cookies-policy.svg";
import informationRemoval from "../assets/images/privacypolicy/information-removal.svg";
import informationRetention from "../assets/images/privacypolicy/information-retention.svg";
import methodsOfCollection from "../assets/images/privacypolicy/methods-of-collection.svg";
import methodsOfInformationUsage from "../assets/images/privacypolicy/methods-of-information-usage.svg";
import consentIcon from "../assets/images/privacypolicy/overview-consent-icon.svg";
import educationIcon from "../assets/images/privacypolicy/overview-education-icon.svg";
import transparencyIcon from "../assets/images/privacypolicy/overview-transparency-icon.svg";
import trustIcon from "../assets/images/privacypolicy/overview-trust-icon.svg";
import policyChanges from "../assets/images/privacypolicy/policy-changes.svg";
import thirdPartyAcceess from "../assets/images/privacypolicy/third-party-access.svg";
import "../assets/styles/privacy-policy.scss";
import ELink from "../components/ELink";
import ScreenLoader from "../components/ScreenLoader";
import { Lookup, t as loct } from "../localization";
import TranslationToggle from "./TranslationToggle";
import ScrollSpy from "bootstrap/js/src/scrollspy";
import clsx from "clsx";
import i18n from "i18next";
import React from "react";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Nav from "react-bootstrap/Nav";
import Navbar from "react-bootstrap/Navbar";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Helmet } from "react-helmet-async";

export default function PrivacyPolicyContent({ mobile }) {
  mobile = Boolean(mobile);
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
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
          <title>{`${t("sections:title")} | ${loct("titles:suma_app")}`}</title>
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
            <TranslationToggle classes="d-flex justify-content-end" />
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
                    label={t("overview:faq")}
                    to="https://mysuma.org/sumaplatform/faq"
                  />
                  <TabLink
                    label={t("overview:contact_us")}
                    to="mailto:apphelp@mysuma.org"
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
              {t("sections:title")}
            </h1>
            <p className="text-center text-secondary mb-5">
              {t("sections:effective") + " " + t("sections:date")}
            </p>
            <PrivacyPolicySection
              id="informationCollected"
              mobile={mobile}
              title={t("sections:information_collected:title")}
              p={t("sections:information_collected:paragraph")}
              list={[
                md("sections:information_collected:list:registration"),
                md("sections:information_collected:list:vendors"),
                md("sections:information_collected:list:subsidy"),
              ]}
            />
            <PrivacyPolicySection
              id="methodsOfCollection"
              mobile={mobile}
              title={t("sections:methods_of_collection:title")}
              p={t("sections:methods_of_collection:paragraph")}
              img={methodsOfCollection}
              list={[
                md("sections:methods_of_collection:list:registration_page"),
                md("sections:methods_of_collection:list:cookies"),
                md("sections:methods_of_collection:list:community_partners"),
              ]}
            />
            <PrivacyPolicySection
              id="methodsOfInformationUsage"
              mobile={mobile}
              title={t("sections:methods_of_information_usage:title")}
              p={t("sections:methods_of_information_usage:paragraph")}
              img={methodsOfInformationUsage}
            >
              <PrivacyPolicySection
                mobile={mobile}
                subsection="true"
                title={t("subsections:services:title")}
                p={t("subsections:services:paragraph")}
              />
              <PrivacyPolicySection
                mobile={mobile}
                subsection="true"
                title={t("subsections:support_subsidy:title")}
                p={t("subsections:support_subsidy:paragraph")}
              />
              <PrivacyPolicySection
                mobile={mobile}
                subsection="true"
                title={t("subsections:communicate_with_you:title")}
                p={
                  <>
                    {md("subsections:communicate_with_you:paragraph")}
                    <a href="#communications">
                      {t("subsections:communicate_with_you:see_communications")}
                    </a>
                  </>
                }
              />
              <PrivacyPolicySection
                mobile={mobile}
                subsection="true"
                title={t("subsections:security_and_fraud_prevention:title")}
                p={t("subsections:security_and_fraud_prevention:paragraph")}
              />
              <PrivacyPolicySection
                mobile={mobile}
                subsection="true"
                title={t("subsections:comply_with_law:title")}
                p={t("subsections:comply_with_law:paragraph")}
              />
            </PrivacyPolicySection>
            <PrivacyPolicySection
              id="cookiesPolicy"
              mobile={mobile}
              title={t("sections:cookies_policy:title")}
              p={t("sections:cookies_policy:paragraph")}
              img={cookiesPolicy}
            >
              <p>{t("sections:cookies_policy:conclusion")}</p>
            </PrivacyPolicySection>
            <PrivacyPolicySection
              id="thirdPartyAccess"
              mobile={mobile}
              title={t("sections:third_party_access:title")}
              p={t("sections:third_party_access:paragraph")}
              img={thirdPartyAcceess}
              list={[
                md("sections:third_party_access:list:service_providers"),
                md("sections:third_party_access:list:with_your_consent"),
                <>
                  {md("sections:third_party_access:list:personal_information")}
                  <a href="#methodsOfInformationUsage">
                    {t("sections:methods_of_information_usage:title")}
                  </a>
                </>,
              ]}
            />
            <PrivacyPolicySection
              id="informationRetentionAndRemoval"
              mobile={mobile}
              title={t("sections:information_retention_and_removal:title")}
              p={t("sections:information_retention_and_removal:paragraph")}
            >
              <PrivacyPolicySection
                mobile={mobile}
                subsection="true"
                title={t("subsections:information_retention:title")}
                p={t("subsections:information_retention:paragraph")}
                img={informationRetention}
                list={[
                  t("subsections:information_retention:list:qualifications"),
                  t("subsections:information_retention:list:maintain_performance"),
                  t("subsections:information_retention:list:subsidy"),
                  t(
                    "subsections:information_retention:list:information_driven_business_decisions"
                  ),
                  t("subsections:information_retention:list:legal_obligations"),
                  t("subsections:information_retention:list:resolving_disputes"),
                ]}
              />
              <PrivacyPolicySection
                mobile={mobile}
                subsection="true"
                title={t("subsections:information_removal:title")}
                img={informationRemoval}
                p={t("subsections:information_removal:paragraph")}
                list={[
                  t("subsections:information_removal:list:deleting_your_account"),
                  t("subsections:information_removal:list:deleting_certain_data"),
                ]}
              />
            </PrivacyPolicySection>
            <PrivacyPolicySection
              id="businessTransfer"
              mobile={mobile}
              title={t("sections:business_transfer:title")}
              p={t("sections:business_transfer:paragraph")}
              img={businessTransfer}
              list={[
                md("sections:business_transfer:list:email"),
                t("sections:business_transfer:list:opt_out"),
              ]}
            />
            <PrivacyPolicySection
              id="childrenUnder13"
              mobile={mobile}
              title={t("sections:children_under_13:title")}
              p={t("sections:children_under_13:paragraph")}
              img={childrenUnder13}
            />
            <PrivacyPolicySection
              id="communications"
              mobile={mobile}
              title={t("sections:communications:title")}
              p={t("sections:communications:paragraph")}
              img={communication}
              list={[
                t("sections:communications:list:platform_communications"),
                t("sections:communications:list:service_messages"),
                t("sections:communications:list:valid_communication_methods"),
              ]}
            />
            <PrivacyPolicySection
              id="futureChangesToPolicy"
              mobile={mobile}
              title={t("sections:future_changes_to_policy:title")}
              p={md("sections:future_changes_to_policy:paragraph")}
              img={policyChanges}
            >
              <p>{md("sections:future_changes_to_policy:conclusion")}</p>
            </PrivacyPolicySection>
            <PrivacyPolicySection
              id="contactInformation"
              mobile={mobile}
              title={t("sections:contact_information:title")}
              p={md("sections:contact_information:paragraph")}
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
            <i
              className={clsx(
                "bi bi-list-ul fs-2",
                !expanded ? "text-dark" : "text-secondary"
              )}
            ></i>
          </Navbar.Toggle>
          <Navbar.Brand className="me-auto d-flex align-items-center">
            {t("common:table_of_contents")}
          </Navbar.Brand>
        </Container>
      )}
      <Navbar.Collapse
        className={clsx("bg-light", mobile && "table-of-contents-collapse p-2")}
      >
        <Container id={id} className="position-relative">
          <Nav className="navbar-nav-scroll navbar-absolute">
            {navLinks.map(({ id, titleNS }, idx) => (
              <React.Fragment key={id}>
                <Nav.Link key={id} href={id} className={clsx("py-1")}>
                  {t(titleNS)}
                </Nav.Link>
                {idx === 0 && <hr className="my-2" />}
              </React.Fragment>
            ))}
          </Nav>
        </Container>
      </Navbar.Collapse>
    </Navbar>
  );
};

const TabLink = ({ to, label }) => {
  return (
    <ELink to={to} className="btn btn-outline-dark border-1">
      {label}
    </ELink>
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

const PrivacyPolicySection = ({
  id,
  title,
  p,
  img,
  list,
  subsection,
  children,
  mobile,
}) => {
  return (
    <div
      id={id}
      className={clsx(!subsection ? "pb-5" : "mt-5", !mobile && !subsection && "mx-lg-5")}
    >
      {!subsection ? (
        <h4 className="mb-4">{title}</h4>
      ) : (
        <h5 className="mb-3">{title}</h5>
      )}
      {img && (
        <img
          src={img}
          alt={title}
          className={clsx(
            "privacy-policy-image d-block ms-4 mb-4",
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

const navLinks = [
  {
    id: "#overview",
    titleNS: "overview:title",
  },
  {
    id: "#informationCollected",
    titleNS: "sections:information_collected:title",
  },
  {
    id: "#methodsOfCollection",
    titleNS: "sections:methods_of_collection:title",
  },
  {
    id: "#methodsOfInformationUsage",
    titleNS: "sections:methods_of_information_usage:title",
  },
  {
    id: "#cookiesPolicy",
    titleNS: "sections:cookies_policy:title",
  },
  {
    id: "#thirdPartyAccess",
    titleNS: "sections:third_party_access:title",
  },
  {
    id: "#informationRetentionAndRemoval",
    titleNS: "sections:information_retention_and_removal:title",
  },
  {
    id: "#businessTransfer",
    titleNS: "sections:business_transfer:title",
  },
  {
    id: "#childrenUnder13",
    titleNS: "sections:children_under_13:title",
  },
  {
    id: "#communications",
    titleNS: "sections:communications:title",
  },
  {
    id: "#futureChangesToPolicy",
    titleNS: "sections:future_changes_to_policy:title",
  },
  {
    id: "#contactInformation",
    titleNS: "sections:contact_information:title",
  },
];

const lu = new Lookup("privacy-policy-strings");
const t = lu.t;
const md = lu.md;
