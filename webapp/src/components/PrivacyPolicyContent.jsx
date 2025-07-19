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
import LayoutContainer from "../components/LayoutContainer";
import ScreenLoader from "../components/ScreenLoader";
import { Lookup, t as loct } from "../localization";
import { useCurrentLanguage } from "../localization/currentLanguage";
import useI18n from "../localization/useI18n";
import useMountEffect from "../shared/react/useMountEffect";
import useGlobalViewState from "../state/useGlobalViewState";
import TranslationToggle from "./TranslationToggle";
import ScrollSpy from "bootstrap/js/src/scrollspy";
import clsx from "clsx";
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
  const [i18nLoading, setI18nLoading] = React.useState(true);
  const { loadLanguageFile } = useI18n();
  const [language] = useCurrentLanguage();
  const { topNav } = useGlobalViewState();
  const topNavHeight = topNav?.clientHeight - 1 || 0;

  useMountEffect(() => {
    loadLanguageFile("privacy_policy").then(() => setI18nLoading(false));
  });

  if (i18nLoading) {
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
          <title>{`${t("sections.title")} | ${loct("titles.suma_app")}`}</title>
        </Helmet>
        {!mobile && (
          <Col className="table-of-contents-desktop d-none d-xl-block border-secondary border-end order-end">
            <TableOfContentsNav />
          </Col>
        )}
        <div
          className={clsx("sticky-top", !mobile && "container d-xl-none")}
          style={{ top: topNavHeight, zIndex: 1 }}
        >
          <TableOfContentsNav mobile={true} />
        </div>
        <LayoutContainer
          gutters={!mobile && true}
          className={clsx("position-relative", !mobile && "privacy-policy-desktop")}
        >
          <Container id="overview" className={clsx(!mobile && "px-xl-3")}>
            <TranslationToggle classes="d-flex justify-content-end" />
            <Row>
              <Col xs={12} className={clsx(!mobile && "col-md-8")}>
                <h1 className="display-4">{t("overview.title")}</h1>
                <p className="fw-light">{t("overview.intro")}</p>
                <p className="pt-2">
                  <a href="#privacy_policy_title">
                    <i>{t("overview.jump_to_privacy_policy")}</i>
                  </a>
                </p>
              </Col>
              <Col xs={12} className={clsx("pt-3", !mobile && "col-md-4")}>
                <Stack gap={3}>
                  <TabLink
                    label={t("overview.faq")}
                    to={`https://mysuma.org/faq-${language}`}
                  />
                  <TabLink label={t("overview.contact_us")} to="mailto:info@mysuma.org" />
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
                  <h1 className="display-5">{t("overview.community_driven_title")}</h1>
                </Col>
                <Col xs={12} className={clsx(!mobile && "col-lg-8 col-xl-7")}>
                  {t("overview.community_driven_intro")}
                </Col>
              </Row>
            </Container>
            <Row>
              <PedalCol
                mobile={mobile}
                sectionKey="overview.transparency"
                img={transparencyIcon}
                imgAlt=""
              />
              <PedalCol
                mobile={mobile}
                sectionKey="overview.consent"
                img={consentIcon}
                imgAlt=""
                right={true}
              />
            </Row>
            <Row className="mt-2">
              <PedalCol
                mobile={mobile}
                sectionKey="overview.education"
                img={educationIcon}
                imgAlt=""
              />
              <PedalCol
                mobile={mobile}
                sectionKey="overview.trust"
                img={trustIcon}
                imgAlt=""
                right={true}
              />
            </Row>
          </Container>
          <hr className="my-5" />
          <Container>
            <h1 id="privacy_policy_title" className="text-center display-4">
              {t("sections.title")}
            </h1>
            <p className="text-center text-secondary mb-5">
              {t("sections.effective") + " " + t("sections.date")}
            </p>
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.information_collected"
              list={[
                t("sections.information_collected.list.registration"),
                t("sections.information_collected.list.vendors"),
                t("sections.information_collected.list.subsidy"),
              ]}
            />
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.methods_of_collection"
              img={methodsOfCollection}
              imgAlt=""
              list={[
                t("sections.methods_of_collection.list.registration_page"),
                t("sections.methods_of_collection.list.cookies"),
                t("sections.methods_of_collection.list.community_partners"),
              ]}
            />
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.methods_of_information_usage"
              img={methodsOfInformationUsage}
              imgAlt=""
            >
              <PrivacyPolicySection mobile={mobile} sectionKey="subsections.services" />
              <PrivacyPolicySection
                mobile={mobile}
                sectionKey="subsections.support_subsidy"
              />
              <PrivacyPolicySection
                mobile={mobile}
                sectionKey="subsections.communicate_with_you"
                p={
                  <>
                    {t("subsections.communicate_with_you.paragraph") + " "}
                    <a href={makeSectionHashtag("sections.communications")}>
                      {t("subsections.communicate_with_you.see_communications")}
                    </a>
                  </>
                }
              />
              <PrivacyPolicySection
                mobile={mobile}
                sectionKey="subsections.security_and_fraud_prevention"
              />
              <PrivacyPolicySection
                mobile={mobile}
                sectionKey="subsections.comply_with_law"
              />
            </PrivacyPolicySection>
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.cookies_policy"
              img={cookiesPolicy}
              imgAlt=""
            >
              <p>{t("sections.cookies_policy.conclusion")}</p>
            </PrivacyPolicySection>
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.third_party_access"
              img={thirdPartyAcceess}
              imgAlt=""
              list={[
                t("sections.third_party_access.list.service_providers"),
                t("sections.third_party_access.list.with_your_consent"),
                <>
                  {t("sections.third_party_access.list.personal_information") + " "}
                  <a href={makeSectionHashtag("sections.methods_of_information_usage")}>
                    {t("sections.methods_of_information_usage.title")}
                  </a>
                </>,
              ]}
            />
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.information_retention_and_removal"
            >
              <PrivacyPolicySection
                mobile={mobile}
                sectionKey="subsections.information_retention"
                img={informationRetention}
                imgAlt=""
                list={[
                  t("subsections.information_retention.list.qualifications"),
                  t("subsections.information_retention.list.maintain_performance"),
                  t("subsections.information_retention.list.subsidy"),
                  t(
                    "subsections.information_retention.list.information_driven_business_decisions"
                  ),
                  t("subsections.information_retention.list.legal_obligations"),
                  t("subsections.information_retention.list.resolving_disputes"),
                ]}
              />
              <PrivacyPolicySection
                mobile={mobile}
                sectionKey="subsections.information_removal"
                img={informationRemoval}
                imgAlt=""
                list={[
                  t("subsections.information_removal.list.deleting_your_account"),
                  t("subsections.information_removal.list.deleting_certain_data"),
                ]}
              />
            </PrivacyPolicySection>
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.business_transfer"
              img={businessTransfer}
              imgAlt=""
              list={[
                t("sections.business_transfer.list.email"),
                t("sections.business_transfer.list.opt_out"),
              ]}
            />
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.children_under_13"
              img={childrenUnder13}
              imgAlt=""
            />
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.communications"
              img={communication}
              imgAlt=""
              list={[
                t("sections.communications.list.platform_communications"),
                t("sections.communications.list.service_messages"),
                t("sections.communications.list.valid_communication_methods"),
              ]}
            />
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.future_changes_to_policy"
              p={t("sections.future_changes_to_policy.paragraph")}
              img={policyChanges}
              imgAlt=""
            >
              <p>{t("sections.future_changes_to_policy.conclusion")}</p>
            </PrivacyPolicySection>
            <PrivacyPolicySection
              mobile={mobile}
              sectionKey="sections.contact_information"
              p={t("sections.contact_information.paragraph")}
            />
          </Container>
        </LayoutContainer>
      </div>
    </div>
  );
}

const TableOfContentsNav = ({ mobile }) => {
  mobile = Boolean(mobile);
  const [expanded, setExpanded] = React.useState(!mobile || false);

  function navRef(el) {
    if (!el) {
      return;
    }
    new ScrollSpy(document.body, {
      target: el,
      smoothScroll: true,
      rootMargin: "0px 0px -60%",
    });
  }

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
      onToggle={(ex) => setExpanded(ex)}
    >
      {mobile && (
        <Container>
          <Navbar.Toggle className={clsx(expanded && "expanded")}>
            <i
              className={clsx(
                "bi bi-card-list fs-1",
                !expanded ? "text-dark" : "text-secondary"
              )}
            ></i>
          </Navbar.Toggle>
          <Navbar.Brand className="me-auto d-flex align-items-center">
            {t("common.table_of_contents")}
          </Navbar.Brand>
        </Container>
      )}
      <Navbar.Collapse
        className={clsx("bg-light", mobile && "table-of-contents-collapse p-2")}
      >
        <Container className="position-relative">
          <Nav ref={navRef} className="navbar-nav-scroll navbar-absolute">
            {navLinkSectionKeys.map((key, idx) => (
              <React.Fragment key={key}>
                <Nav.Link href={makeSectionHashtag(key)} className="py-1">
                  {t(key + ".title")}
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

const PedalCol = ({ sectionKey, img, imgAlt, right, mobile }) => {
  const title = t(sectionKey + ".title");
  return (
    <Col xs={12} className={clsx("mb-4", !mobile && "mb-lg-0 px-sm-5 px-lg-2 col-lg-6")}>
      <Stack
        direction="horizontal"
        gap={3}
        className={clsx("align-items-start justify-content-center")}
      >
        <img
          src={img}
          alt={imgAlt}
          className={clsx(right && "order-last", right && !mobile && "order-lg-last")}
        />
        <div
          className={clsx(
            "mt-4",
            !right && !mobile && "order-lg-first",
            right && !mobile && "order-lg-last"
          )}
        >
          <h5>{title}</h5>
          <p className="fw-light">{t(sectionKey + ".statement")}</p>
        </div>
      </Stack>
    </Col>
  );
};

const PrivacyPolicySection = ({ p, img, imgAlt, list, sectionKey, children, mobile }) => {
  const subsection = sectionKey.startsWith("sub");
  const id = subsection ? undefined : makeSectionId(sectionKey);
  const title = t(sectionKey + ".title");
  p = p || t(sectionKey + ".paragraph");
  return (
    <div
      id={id}
      className={clsx(!subsection && "mt-5", !mobile && !subsection && "mx-lg-5")}
    >
      {!subsection ? (
        <h4 className="mb-4 pt-4">{title}</h4>
      ) : (
        <h5 className="mb-3">{title}</h5>
      )}
      {img && (
        <img
          src={img}
          alt={imgAlt}
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
            <li key={idx + sectionKey} className="ps-3 pb-2">
              {b}
            </li>
          ))}
        </ul>
      )}
      {children}
    </div>
  );
};

function makeSectionHashtag(key) {
  return "#" + makeSectionId(key);
}
function makeSectionId(key) {
  return key.replace(".", "_");
}

const navLinkSectionKeys = [
  "overview",
  "sections.information_collected",
  "sections.methods_of_collection",
  "sections.methods_of_information_usage",
  "sections.cookies_policy",
  "sections.third_party_access",
  "sections.information_retention_and_removal",
  "sections.business_transfer",
  "sections.children_under_13",
  "sections.communications",
  "sections.future_changes_to_policy",
  "sections.contact_information",
];

const lu = new Lookup("privacy_policy");
const t = lu.t;
