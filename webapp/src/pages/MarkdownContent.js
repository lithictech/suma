import ELink from "../components/ELink";
import ScreenLoader from "../components/ScreenLoader";
import TopNav from "../components/TopNav";
import useMountEffect from "../shared/react/useMountEffect";
import { LayoutContainer } from "../state/withLayout";
import i18n from "i18next";
import React from "react";
import { Helmet } from "react-helmet-async";
import ReactMarkdown from "react-markdown";

export default function MarkdownContent({ namespace }) {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  useMountEffect(() => {
    i18n.loadNamespaces(namespace).then(() => setI18NextLoading(false));
  });
  if (i18nextLoading) {
    return <ScreenLoader show />;
  }
  const titleKey = `strings:titles:${namespace}`;
  const contentKey = `${namespace}:contents`;
  return (
    <div className="bg-light">
      <div className="main-container">
        <Helmet>
          <title>{`${i18n.t(titleKey)} | ${i18n.t("strings:titles:suma_app")}`}</title>
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
          <ReactMarkdown components={{ a: MdLink }}>{i18n.t(contentKey)}</ReactMarkdown>
        </LayoutContainer>
      </div>
    </div>
  );
}

function MdLink({ node, ...rest }) {
  return <ELink {...rest} />;
}
