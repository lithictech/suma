import ScreenLoader from "../components/ScreenLoader";
import SumaMarkdown from "../components/SumaMarkdown";
import TopNav from "../components/TopNav";
import { t as loct } from "../localization";
import useMountEffect from "../shared/react/useMountEffect";
import { LayoutContainer } from "../state/withLayout";
import i18n from "i18next";
import React from "react";
import { Helmet } from "react-helmet-async";

export default function MarkdownContent({ namespace }) {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  useMountEffect(() => {
    i18n.loadNamespaces(namespace).then(() => setI18NextLoading(false));
  });
  if (i18nextLoading) {
    return <ScreenLoader show />;
  }
  const title = loct(`titles:${namespace}`) + " | " + loct("titles:suma_app");
  const contentKey = `${namespace}:contents`;
  return (
    <div className="bg-light">
      <div className="main-container">
        <Helmet>
          <title>{title}</title>
        </Helmet>
        <div className="sticky-top">
          <TopNav />
        </div>
        <LayoutContainer
          top={true}
          gutters="true"
          className="mx-auto pb-4"
          style={{ maxWidth: "500px" }}
        >
          <SumaMarkdown>{i18n.t(contentKey)}</SumaMarkdown>
        </LayoutContainer>
      </div>
    </div>
  );
}
