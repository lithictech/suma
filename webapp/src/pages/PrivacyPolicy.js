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
import ScreenLoader from "../components/ScreenLoader";
import useI18Next from "../localization/useI18Next";
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
import { Link } from "react-router-dom";

export default function PrivacyPolicy() {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  const [expanded, setExpanded] = React.useState(false);
  const scrollSpyElement = document.getElementById("scrollspy");
  const t = (key, options = {}) => {
    return i18n.t("privacy-policy-strings:" + key, options);
  };

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
        <title>{`${t("title")} | ${i18n.t("strings:titles:suma_app")}`}</title>
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
            Table of Contents
          </Navbar.Brand>
        </Container>
        <Navbar.Collapse className="table-of-contents-collapse">
          <Container id="scrollspy" className="position-relative">
            <Nav className="navbar-nav-scroll navbar-absolute">
              <Nav.Link href="#overview">Overview</Nav.Link>
              <Nav.Link href="#informationCollected">
                What information is collected?
              </Nav.Link>
              <Nav.Link href="#methodsOfCollection">Methods of collection</Nav.Link>
              <Nav.Link href="#methodsOfDataUsage">Methods of data usage</Nav.Link>
              <Nav.Link href="#cookiesPolicy">Cookies policy</Nav.Link>
              <Nav.Link href="#thirdPartyAccess">Third-party access</Nav.Link>
              <Nav.Link href="#dataRetentionAndRemoval">
                Data retention and removal
              </Nav.Link>
              <Nav.Link href="#businessTransfer">Business transfer</Nav.Link>
              <Nav.Link href="#childrenUnder13">Children under 13</Nav.Link>
              <Nav.Link href="#communication">Communication</Nav.Link>
              <Nav.Link href="#futureChangesToPolicy">Future changes to policy</Nav.Link>
              <Nav.Link href="#disputeResolution">Dispute resolution</Nav.Link>
              <Nav.Link href="#contactInformation">Contact information</Nav.Link>
            </Nav>
          </Container>
        </Navbar.Collapse>
      </Navbar>
      <Container className="position-relative" tabIndex="0">
        <SpanishTranslatorButton id="overview" />
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
              <TabLink
                label="FAQ"
                title="Frequently asked questions"
                to="/frequently-asked-questions"
              />
              <TabLink label="Contact Us" title="Contact us" to="/contact-us" />
            </Stack>
          </Col>
        </Row>
        <Container className="community-driven-container border border-1 border-dark bg-white my-5 p-4">
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
        <p className="text-center">Effective: [Date here]</p>
        <PrivacyPolicySection
          id="informationCollected"
          title="What information is collected?"
          p="We collect the minimum information needed to create your suma platform account, work with community partners, connect you with vendors, and secure subsidy: Registration: We collect your name, telephone number, email, billing information, and community partner name when you create your suma platform account."
          list={[
            "Registration: We collect your name, telephone number, email, billing information, and community partner name when you create your suma platform account.",
            "Vendors: We collect data about what goods and services you access and purchase via the suma platform.",
            "Subsidy: We collect data necessary to secure third party subsidy that reduces the cost of goods and services from vendors via the suma platform.",
          ]}
        />
        <PrivacyPolicySection
          id="methodsOfCollection"
          title="Methods of collection"
          p="Your trust in, consent to and understanding of our privacy policy are fundamental to the suma platform. To provide platform services, we collect information from the following methods:"
          img={methodsOfCollection}
          list={[
            "We use our registration page to collect information when you create your suma account.",
            "Cookies and Log Files. We use cookies to track who you are logged in as. We use log files to track all activity on the platform. Please see our cookies policy to learn about the cookies we use and why. ",
            "______. We use _____ to collect information when you access goods and services from vendors via the suma platform",
            "Community Partners. We collect data from community partners to help us qualify you for vendor discounts on the suma platform as well as to support third party subsidy that reduces the cost of goods and services from vendors via the suma platform.",
          ]}
        />
        <PrivacyPolicySection
          id="methodsOfDataUsage"
          title="Methods of data usage"
          p="We use personal data to power suma platform services, to process your transactions, to qualify you for platform vendor discounts, to support third party subsidy, to aggregate platform usage, to educate community partners, to communicate with you, for security and fraud prevention, and to comply with the law:"
          img={methodsOfDataUsage}
          list={[
            "Qualify you for vendor discounts: Community members told us that vendor discount programs are frustrating and time consuming, so we built the platform to make it easier for our users to qualify for vendor discounts. With your consent, we may use your personal data to qualify you for these discounts.",
            "Support third party subsidy: Funders may want to put money into the suma platform to reduce the cost of food, transportation, utilities or other goods and services for platform users. With your consent, we may use your personal data to secure or report on these investments.",
            "Aggregated platform usage: We anonymize and aggregate platform usage data to demonstrate to funders and partners the impact and reach of the platform. You can opt out of being included in this anonymized reporting through your Preferences page in the suma application.",
            "Educate community partners: Affordable housing providers and other community partners may request anonymized and aggregated data on how their residents are using the platform. For example, a partner may request anonymized and aggregated transportation data to help them advocate for more e-bike stations in their neighborhood or request anonymized and aggregated food data to help them advocate for a farmers market at their affordable housing complex. With your consent, we may share aggregate or anonymized data with these partners.",
            "Communicate with you: We may use your data to respond to your communications, reach out to you about your transactions or account, market the platform, provide other relevant information, or request information or feedback. ",
            "Security and fraud prevention: [Needs More Context Here]",
            "Comply with the law: We may share your personal information if we believe its required by applicable law, regulation, operating license or agreement, legal process or governmental request, or where the disclosure is otherwise appropriate due to safety or similar concerns. For example, we may share your personal information if an e-scooter is lost or damaged in order to ___.",
          ]}
        />
        <PrivacyPolicySection
          id="cookiesPolicy"
          title="Cookies policy"
          p="We use cookies to help us manage the platform. Cookies are small text files that are stored on your device when you visit the Suma platform. A cookie contains a unique code, which we use to recognize your device when you return to the Suma platform."
          img={cookiesPolicy}
        >
          <p>
            The Suma platform only uses essential cookies known as “Session Cookies”,
            which allow the platform to know who you are signed in as. They are required
            for the platform to work. Session Cookies expire periodically as well as when
            you log out of the suma platform. The suma platform does not use persistent,
            optional or non-essential cookies.
          </p>
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="thirdPartyAccess"
          title="Third-party access"
          p="Suma does not share personal information about you with any third parties for their own marketing purposes. We do share this information with trusted and vetted third parties (platform vendors, subsidy providers, community partners, service providers to the platform), via the platform dashboard, for security and fraud prevention, to comply with the law or in the event of a dispute:"
          img={thirdPartyAcceess}
        >
          <PrivacyPolicySection
            subsection="true"
            title="Platform vendors"
            p="We may share certain data with a platform vendor when you use the platform to access goods or services from that vendor. For example, if you request an e-scooter ride from Operator X via the platform, we may share certain data with Operator X to confirm you are a Suma user and/or to confirm you are eligible for Operator X’s discount program."
          />
          <PrivacyPolicySection
            subsection="true"
            title="Subsidy providers"
            p="We may share certain data with a subsidy provider when you use their subsidy to access goods or services from a platform vendor. For example, a subsidy provider may fund the platform to help users access e-bike services at a lower cost. If you use such subsidy to access e-bike services via the platform at a lower cost, we may share certain data with that subsidy provider to report on the use of their subsidy."
          />
          <PrivacyPolicySection
            subsection="true"
            title="Community Partners"
            p="We may share certain data with affordable housing providers and other community community partners on how their residents are using the platform. For example, a community partner may request anonymized and aggregated transportation data to help them advocate for more e-bike stations in their neighborhood or may request anonymized and aggregated food data to help them advocate for a farmers market at their affordable housing complex. With your consent, we may share aggregate or anonymized data with these partners."
          />
          <PrivacyPolicySection
            subsection="true"
            title="Service providers"
            p="These are providers who help us operate the Suma platform, and include payment processors and facilitators, identity verification providers, and cloud hosting services."
          />
          <PrivacyPolicySection
            subsection="true"
            title="Platform dashboard"
            p="We use data to create dashboards that show how the platform is benefiting you and the broader suma user community. For example, a dashboard might show how much money all platform users combined saved on food purchases in the most recent month. Your food purchasing data may be anonymized and aggregated into such a dashboard. You can opt out of being included in anonymized dashboards. Security and fraud prevention."
          />
          <PrivacyPolicySection
            subsection="true"
            title="Comply with the Law"
            p="We may share your personal information if we believe it’s required by applicable law, regulation, operating license or agreement, legal process or governmental request, or where the disclosure is otherwise appropriate due to safety or similar concerns. For example, we may share your personal data, including trip or order information, with an e-scooter company if their e-scooter is lost or damaged at or near the time you used the Suma platform to access their e-scooter services."
          />
          <PrivacyPolicySection
            subsection="true"
            title="Security and fraud prevention"
            p="[needs more context]"
          />
          <PrivacyPolicySection
            subsection="true"
            title="Disputes"
            p="[needs more context]"
          />
          <PrivacyPolicySection
            subsection="true"
            title="With your consent"
            p="We may share your personal data to additional third parties if we notify you and you consent to the sharing."
          />
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="dataRetentionAndRemoval"
          title="Data retention and removal"
          p="We have the following standards for retaining and deleting Suma platform data:"
        >
          <PrivacyPolicySection
            subsection="true"
            title="Data retention"
            p="We will retain your information for the suma platform’s legitimate and essential business purposes as long as your suma platform account is active. These purposes include:"
            img={dataRetention}
            list={[
              "maintaining the performance of the platform ",
              "qualifying you for platform vendor discounts, supporting third party subsidy, creating platform dashboards, and educating community partners ",
              "making data-driven business decisions about new platform features and offerings ",
              "complying with our legal obligations",
              "resolving disputes",
            ]}
          />
          <PrivacyPolicySection
            subsection="true"
            title="Data removal"
            img={dataRemoval}
            p="You may request deletion of your suma platform account at any time from your Preferences page in the Suma app. We will delete your account and data within 7 days after you make a deletion request. Things to note:"
            list={[
              "We may request your consent to anonymize and retain your data to educate community partners or for platform dashboard purposes.",
              "Deleting your account may not free up your email address or phone number for reuse on a new account.",
              "We may not be able to delete certain data because of legal, regulatory or subsidy reporting requirements, for purposes of safety, security, and fraud prevention, or because of an issue relating to your account such as an outstanding credit or an unresolved claim or dispute.",
            ]}
          />
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="businessTransfer"
          title="Business transfer"
          p="We may choose to sell assets of the suma platform or buy assets for the platform. These transactions may be necessary and in our legitimate interests, particularly our interest in growing the platform to serve more community members and to offer more goods and services. User information is typically an asset that is transferred in these transactions (such as a sale, merger, liquidation, receivership, or transfer of all or substantially all of the suma platform’s assets)."
          img={businessTransfer}
        >
          <p>
            If we intend to transfer information about you, we will let you know about the
            change by email and/or by posting a notice on the suma platform’s homepage
            (https://app.mysuma.org/app/); and you will have a chance to opt out before
            information about you becomes subject to a different Privacy Policy.
          </p>
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="childrenUnder13"
          title="Children under 13"
          p="The Suma platform is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are under 13, please do not provide any information on the Suma platform."
        />
        <PrivacyPolicySection
          id="communication"
          title="Communication"
          p="Sometimes we will need to communicate with you about the platform, including things like new vendors, new community partners, savings or subsidy opportunities, community events and service messages. We will use the communication preferences and contact information you have shared with us to communicate with you via email, text and/or in-platform tools. Communications will take place in the language you indicate in your communication preferences. You may change your communication preferences and contact information at any time, except:"
          img={communication}
          list={[
            "You cannot opt out of receiving service messages from us, including privacy policy updates, security notices and legal notices.",
            "You are required to keep a valid email address on file to receive messages.",
          ]}
        />
        <PrivacyPolicySection
          id="futureChangesToPolicy"
          title="Future changes to policy"
          p="We may change suma platform Privacy Policy from time to time. If we do change the Suma platform Privacy Policy, we will let you know about the change by email and/or by posting a notice on the Suma platform’s homepage (https://app.mysuma.org/app/). This notice will let you know what is changing, why it is changing and how it is changing. We will provide this notice at least 30 days before the changes take effect unless the law requires a different notice period. You will have the chance to consent to the changes at your first login to the platform after the changes take effect. If you do not consent to the changes, you will not be able to use the platform (see ____)"
          img={policyChanges}
        >
          <p>
            You can always find the most recent version of the suma platform privacy
            policy here (url). Please contact apphelp@mysuma.org for any questions or
            concerns regarding our policy changes.
          </p>
        </PrivacyPolicySection>
        <PrivacyPolicySection
          id="disputeResolution"
          title="Dispute resolution"
          p="If you have any questions or concerns about our use or disclosure of information, please reach out to us via apphelp@mysuma.org. We are here to listen to all of your concerns. If we cannot resolve your concern, we will/the next step is… [Needs more context here]"
          img={disputeResolution}
        />
        <PrivacyPolicySection
          id="contactInformation"
          title="Contact information"
          p="If you have questions about this Privacy Policy, we are here to listen. Please contact Suma at apphelp@mysuma.org. We are also available to host remote or in person meetings to provide information and answer questions about the Privacy Policy."
        />
      </Container>
    </>
  );
}

const PrivacyPolicySection = ({ id, title, p, img, list, subsection, children }) => {
  return (
    <div
      id={id}
      className={clsx(!subsection ? "privacy-policy-section-padding" : "pt-3")}
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
        <img src={img} alt={heading} className={clsx(right && "order-first")} />
      </Stack>
    </Col>
  );
};

const SpanishTranslatorButton = ({ id }) => {
  const { language, changeLanguage } = useI18Next();
  return (
    <div id={id} className="d-flex justify-content-end">
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
};
