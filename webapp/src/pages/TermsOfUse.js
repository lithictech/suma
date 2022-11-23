import ELink from "../components/ELink";
import ScreenLoader from "../components/ScreenLoader";
import TopNav from "../components/TopNav";
import externalLinks from "../modules/externalLinks";
import { LayoutContainer } from "../state/withLayout";
import i18n from "i18next";
import _ from "lodash";
import React from "react";
import { Helmet } from "react-helmet-async";
import ReactMarkdown from "react-markdown";

export default function TermsOfUse() {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  React.useEffect(() => {
    // initialize isolated translations
    Promise.delayOr(500, i18n.loadNamespaces("terms-strings")).then(() => {
      setI18NextLoading(false);
    });
  }, []);
  if (i18nextLoading) {
    return <ScreenLoader show />;
  }
  return (
    <div className="bg-light">
      <div className="main-container">
        <Helmet>
          <title>{`${t("title")} | ${i18n.t("strings:titles:suma_app")}`}</title>
        </Helmet>
        <div className="sticky-top">
          <TopNav />
        </div>
        <LayoutContainer
          top={true}
          gutters="true"
          className="mx-auto pb-4"
          style={{ width: "500px" }}
        >
          <h1>{t("title")}</h1>
          <p>{t("last_modified")}</p>
          <TermsSection titleKey="acceptance" itemKeys={["p1_md", "p2_md", "p3"]} />
          <TermsSection
            titleKey="access"
            itemKeys={["p1", "p2", ["l1", "l2"], "p3_md", "p4", "p5"]}
          />
          <TermsSection
            titleKey="intellectual_property_rights"
            itemKeys={["p1", "p2", "p3"]}
          />
          <TermsSection titleKey="trademarks" itemKeys={["p1"]} />
          <TermsSection
            titleKey="prohibited_uses"
            itemKeys={["p1", ["l1", "l2", "l3"], "p2", ["l4", "l5"]]}
          />
          <TermsSection titleKey="reliance_on_information" itemKeys={["p1"]} />
          <TermsSection titleKey="changes" itemKeys={["p1"]} />
          <TermsSection titleKey="your_information" itemKeys={["p1_md"]} />
          <TermsSection titleKey="purchases" itemKeys={["p1_md", "p2"]} />
          <TermsSection titleKey="payment" itemKeys={["p1", "p2", "p3", "p4", "p5"]} />
          <TermsSection titleKey="geographic_restrictions" itemKeys={["p1"]} />
          <TermsSection titleKey="disclaimer" itemKeys={["p1", "p2", "p3", "p4"]} />
          <TermsSection titleKey="liability" itemKeys={["p1", "p2", "p3"]} />
          <TermsSection titleKey="indemnification" itemKeys={["p1"]} />
          <TermsSection titleKey="law" itemKeys={["p1", "p2"]} />
          <TermsSection titleKey="waiver" itemKeys={["p1"]} />
          <TermsSection titleKey="entire_agreement" itemKeys={["p1"]} />
          <TermsSection titleKey="comments" itemKeys={["p1", "p2_md"]} />
        </LayoutContainer>
      </div>
    </div>
  );
}

const TermsSection = ({ titleKey, itemKeys }) => {
  return (
    <div className="mt-5 mb-2">
      {titleKey && <h4>{t(titleKey + ":title")}</h4>}
      {itemKeys.map((suffixKey, idx) => {
        if (_.isArray(suffixKey)) {
          return <List key={idx} titleKey={titleKey} list={suffixKey} />;
        }
        return (
          <p key={idx}>
            <TranslateKeys titleKey={titleKey} suffixKey={suffixKey} />
          </p>
        );
      })}
    </div>
  );
};

const List = ({ titleKey, list }) => {
  return (
    <ul>
      {list.map((listKey, idx) => (
        <li key={idx} className="ps-3 pb-2">
          <TranslateKeys titleKey={titleKey} suffixKey={listKey} />
        </li>
      ))}
    </ul>
  );
};

const TranslateKeys = ({ titleKey, suffixKey }) => {
  const trans = suffixKey.endsWith("_md") ? md : t;
  return trans(`${titleKey}:${suffixKey}`);
};

const t = (key, options = {}) => {
  return i18n.t("terms-strings:terms_of_use:" + key, options);
};

const md = (key, mdoptions = {}, i18noptions = {}) => {
  const MdLink = ({ node, ...rest }) => {
    return <ELink {...rest} />;
  };
  const str = t(key, { ...i18noptions, externalLinks });
  const components = { a: MdLink, p: React.Fragment, ...mdoptions.components };
  return <ReactMarkdown components={components}>{str}</ReactMarkdown>;
};
