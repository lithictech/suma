import LoadingPage from "../components/LoadingPage.tsx";
import SumaMarkdown from "../components/SumaMarkdown";
import { t as loct } from "../localization";
import i18n from "../localization/i18n";
import useI18n from "../localization/useI18n";
import useMountEffect from "../state/useMountEffect";
import Page from "../ui/Page.tsx";
import "./MarkdownContent.css";
import React from "react";
import { Helmet } from "react-helmet-async";

interface MarkdownContentProps {
  languageFile: string;
}

export default function MarkdownContent({ languageFile }: MarkdownContentProps) {
  const [i18nLoading, setI18nLoading] = React.useState(true);
  const { loadLanguageFile } = useI18n();
  useMountEffect(() => {
    loadLanguageFile(languageFile).then(() => setI18nLoading(false));
  });
  if (i18nLoading) {
    return <LoadingPage page />;
  }
  const title = loct(`titles.${languageFile}`) + " | " + loct("titles.suma_app");
  const contentKey = `${languageFile}.contents`;
  return (
    <Page className="markdown-content">
      <Helmet>
        <title>{title}</title>
      </Helmet>
      <SumaMarkdown>{i18n.t(contentKey)}</SumaMarkdown>
    </Page>
  );
}
