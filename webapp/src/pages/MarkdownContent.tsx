import ContentPageHeader from "../components/ContentPageHeader.tsx";
import LoadingPage from "../components/LoadingPage.tsx";
import SumaMarkdown from "../components/SumaMarkdown";
import { t } from "../localization";
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
  const title = t(`titles.${languageFile}`) + " | " + t("titles.suma_app");
  const contentKey = `${languageFile}.contents`;
  return (
    <Page buffer={false} gap={0}>
      <Helmet>
        <title>{title}</title>
      </Helmet>
      <ContentPageHeader title={t("common.terms_of_use")} />
      <div className="markdown-content">
        <SumaMarkdown>{i18n.t(contentKey)}</SumaMarkdown>
      </div>
    </Page>
  );
}
