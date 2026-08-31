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
import sumaLogo from "../assets/images/suma-logo-word-512.png";
import ScreenLoader from "../components/ScreenLoader";
import { imageAltT, Lookup, t as loct } from "../localization";
import { useCurrentLanguage } from "../localization/currentLanguage";
import useI18n from "../localization/useI18n";
import { externalUrl } from "../routing/RoutePath.ts";
import useMountEffect from "../state/useMountEffect";
import useScrollToHashOnMount from "../state/useScrollToHashOnMount.tsx";
import Button from "../ui/Button.tsx";
import Card from "../ui/Card.tsx";
import CardBody from "../ui/CardBody.tsx";
import Page from "../ui/Page.tsx";
import Stack from "../ui/Stack";
import "./PrivacyPolicy.css";
import TranslationToggle from "./TranslationToggle";
import clsx from "clsx";
import React from "react";
import { Helmet } from "react-helmet-async";

const Container = (props: any) => <div {...props} />;

export default function PrivacyPolicy() {
  const [i18nLoading, setI18nLoading] = React.useState(true);
  const { loadLanguageFile } = useI18n();
  const [language] = useCurrentLanguage();
  const scrollToHash = useScrollToHashOnMount();

  useMountEffect(() => {
    loadLanguageFile("privacy_policy").then(() => {
      setI18nLoading(false);
      scrollToHash();
    });
  });

  if (i18nLoading) {
    return <ScreenLoader show />;
  }
  return (
    <Page buffer={false} gap={0} className="pp">
      <Helmet>
        <title>{`${t("sections.title")} | ${loct("titles.suma_app")}`}</title>
      </Helmet>

      <Stack row gap={3} center className="bgcolor-tint-primary px-3 py-2">
        <img src={sumaLogo} height={64} alt={imageAltT("suma_logo")} />
        <Stack col gap={1}>
          <h1>Privacy Policy</h1>
          <TranslationToggle />
        </Stack>
      </Stack>

      <TableOfContentsNav />
      <Stack col gap={3} className="p-3">
        <Stack id="overview" col gap={5} className="pp-target">
          <p className="fw-light">{t("overview.intro")}</p>
          <p className="pt-2">
            <a href="#title">
              <i>{t("overview.jump_to_privacy_policy")}</i>
            </a>
          </p>
          <Button
            variant="outline"
            to={externalUrl(`https://mysuma.org/faq-${language}`)}
          >
            {t("overview.faq")}
          </Button>
          <Button variant="outline" to={externalUrl(`mailto:info@mysuma.org`)}>
            {t("overview.contact_us")}
          </Button>
          <Card>
            <CardBody>
              <h2 className="display-5">{t("overview.community_driven_title")}</h2>
              {t("overview.community_driven_intro")}
            </CardBody>
          </Card>
          <PedalCol sectionKey="overview.transparency" img={transparencyIcon} imgAlt="" />
          <PedalCol
            sectionKey="overview.consent"
            img={consentIcon}
            imgAlt=""
            right={true}
          />
          <PedalCol sectionKey="overview.education" img={educationIcon} imgAlt="" />
          <PedalCol sectionKey="overview.trust" img={trustIcon} imgAlt="" right={true} />
        </Stack>
        <hr className="my-5" />
        <Container>
          <h1 id="title" className="text-center mb-2 pp-target">
            {t("sections.title")}
          </h1>
          <p className="text-center mb-5">
            {t("sections.effective") + " " + t("sections.date")}
          </p>
          <PrivacyPolicySection
            sectionKey="sections.information_collected"
            list={[
              t("sections.information_collected.list.registration"),
              t("sections.information_collected.list.vendors"),
              t("sections.information_collected.list.subsidy"),
            ]}
          />
          <PrivacyPolicySection
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
            sectionKey="sections.methods_of_information_usage"
            img={methodsOfInformationUsage}
            imgAlt=""
          >
            <PrivacyPolicySection sectionKey="subsections.services" />
            <PrivacyPolicySection sectionKey="subsections.support_subsidy" />
            <PrivacyPolicySection
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
            <PrivacyPolicySection sectionKey="subsections.security_and_fraud_prevention" />
            <PrivacyPolicySection sectionKey="subsections.comply_with_law" />
          </PrivacyPolicySection>
          <PrivacyPolicySection
            sectionKey="sections.cookies_policy"
            img={cookiesPolicy}
            imgAlt=""
          >
            <p>{t("sections.cookies_policy.conclusion")}</p>
          </PrivacyPolicySection>
          <PrivacyPolicySection
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
          <PrivacyPolicySection sectionKey="sections.information_retention_and_removal">
            <PrivacyPolicySection
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
            sectionKey="sections.business_transfer"
            img={businessTransfer}
            imgAlt=""
            list={[
              t("sections.business_transfer.list.email"),
              t("sections.business_transfer.list.opt_out"),
            ]}
          />
          <PrivacyPolicySection
            sectionKey="sections.children_under_13"
            img={childrenUnder13}
            imgAlt=""
          />
          <PrivacyPolicySection
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
            sectionKey="sections.future_changes_to_policy"
            p={t("sections.future_changes_to_policy.paragraph")}
            img={policyChanges}
            imgAlt=""
          >
            <p>{t("sections.future_changes_to_policy.conclusion")}</p>
          </PrivacyPolicySection>
          <PrivacyPolicySection
            sectionKey="sections.contact_information"
            p={t("sections.contact_information.paragraph")}
          />
        </Container>
      </Stack>
    </Page>
  );
}

const TableOfContentsNav = () => {
  const detailsRef = React.useRef<HTMLDetailsElement>(null);
  return (
    <nav className="pp-toc" aria-label="Table of contents">
      <details ref={detailsRef}>
        <summary>Contents</summary>
        <ul>
          {navLinkSectionKeys.map((arg) => {
            let target: string, label: string;
            if (typeof arg === "string") {
              target = arg;
              label = target + ".title";
            } else {
              target = arg.target;
              label = arg.label;
            }
            return (
              <li key={target}>
                <a
                  href={makeSectionHashtag(target)}
                  onClick={() => detailsRef.current?.removeAttribute("open")}
                >
                  {t(label)}
                </a>
              </li>
            );
          })}
        </ul>
      </details>
    </nav>
  );
};

interface PedalColProps {
  sectionKey: string;
  img: string;
  imgAlt: string;
  right?: boolean;
}

const PedalCol = ({ sectionKey, img, imgAlt, right }: PedalColProps) => {
  const title = t(sectionKey + ".title");
  return (
    <Stack
      gap={5}
      center
      className={clsx("justify-content-center")}
      style={{ flexDirection: right ? "row-reverse" : "row" }}
    >
      <img src={img} alt={imgAlt} />
      <Stack col gap={3}>
        <h2>{title}</h2>
        <p>{t(sectionKey + ".statement")}</p>
      </Stack>
    </Stack>
  );
};

interface PrivacyPolicySectionProps {
  p?: React.ReactNode;
  img?: string;
  imgAlt?: string;
  list?: React.ReactNode[];
  sectionKey: string;
  children?: React.ReactNode;
}

const PrivacyPolicySection = ({
  p,
  img,
  imgAlt,
  list,
  sectionKey,
  children,
}: PrivacyPolicySectionProps) => {
  const subsection = sectionKey.startsWith("sub");
  const id = subsection ? undefined : makeSectionId(sectionKey);
  const title = t(sectionKey + ".title");
  p = p || t(sectionKey + ".paragraph");
  return (
    <div id={id} className={clsx("pp-target", !subsection && "mt-5")}>
      {subsection ? (
        <h4 className="mb-3">{title}</h4>
      ) : (
        <h3 className="mb-4 pt-4">{title}</h3>
      )}
      {img && (
        <img src={img} alt={imgAlt} className={clsx("pp-image d-block ms-4 mb-4")} />
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

function makeSectionHashtag(key: string) {
  return "#" + makeSectionId(key);
}
function makeSectionId(key: string) {
  return key.replace(".", "_");
}

const navLinkSectionKeys = [
  "overview",
  { label: "sections.title", target: "title" },
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
