import ELink from "../components/ELink";
import ScreenLoader from "../components/ScreenLoader";
import TopNav from "../components/TopNav";
import externalLinks from "../modules/externalLinks";
import { LayoutContainer } from "../state/withLayout";
import i18n from "i18next";
import React from "react";
import { Helmet } from "react-helmet-async";
import ReactMarkdown from "react-markdown";

export default function TermsOfSale() {
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
          {md("description_md")}
          {md("one_md")}
          {md("two_md")}
          {md("three_md")}
          {md("four_md")}
          {md("five_md")}
          {md("six_md")}
          {md("seven_md")}
          {md("eight_md")}
          {md("nine_md")}
          {md("ten_md")}
          {md("eleven_md")}
          {md("twelve_md")}
          {md("thirteen_md")}
        </LayoutContainer>
      </div>
    </div>
  );
}

const t = (key, options = {}) => {
  return i18n.t("terms-strings:terms_of_sale:" + key, options);
};

const md = (key, mdoptions = {}, i18noptions = {}) => {
  const MdLink = ({ node, ...rest }) => {
    return <ELink {...rest} />;
  };
  const P = ({ node, ...rest }) => {
    return <p {...rest} />;
  };
  const str = t(key, { ...i18noptions, externalLinks });
  const components = { a: MdLink, p: P, ...mdoptions.components };
  return <ReactMarkdown components={components}>{str}</ReactMarkdown>;
};
