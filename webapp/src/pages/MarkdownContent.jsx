import LayoutContainer from "../components/LayoutContainer";
import ScreenLoader from "../components/ScreenLoader";
import SumaMarkdown from "../components/SumaMarkdown";
import TopNav from "../components/TopNav";
import { t as loct } from "../localization";
import i18n from "../localization/i18n";
import useI18n from "../localization/useI18n";
import useMountEffect from "../shared/react/useMountEffect";
import React from "react";
import { Helmet } from "react-helmet-async";

export default function MarkdownContent({ languageFile }) {
  const [i18nLoading, setI18nLoading] = React.useState(true);
  const { loadLanguageFile } = useI18n();
  useMountEffect(() => {
    loadLanguageFile(languageFile).then(() => setI18nLoading(false));
  });
  if (i18nLoading) {
    return (
      <div className="bg-light">
        <div className="main-container">
          <ScreenLoader show />
        </div>
      </div>
    );
  }
  const title = loct(`titles:${languageFile}`) + " | " + loct("titles:suma_app");
  const contentKey = `${languageFile}:contents`;
  return (
    <div className="bg-light">
      <div className="main-container">
        <Helmet>
          <title>{title}</title>
        </Helmet>
        <TopNav />
        <LayoutContainer top gutters className="pb-4" style={{ maxWidth: "500px" }}>
          <SumaMarkdown>{i18n.t(contentKey)}</SumaMarkdown>
        </LayoutContainer>
      </div>
    </div>
  );
}
