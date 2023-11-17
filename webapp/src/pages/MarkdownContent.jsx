import ScreenLoader from "../components/ScreenLoader";
import SumaMarkdown from "../components/SumaMarkdown";
import TopNav from "../components/TopNav";
import { t as loct } from "../localization";
import useMountEffect from "../shared/react/useMountEffect";
import { LayoutContainer } from "../state/withLayout";
import i18n from "i18next";
import React from "react";
import Row from "react-bootstrap/Row";
import { Helmet } from "react-helmet-async";

/**
 * Loads namespaces with i18n, then renders markdown content with SumaMarkdown.
 * The rendered content is separated by a divider line.
 *
 * The title is localized with i18n strings.json, i.e `titles:[namespace]`.
 *
 * @param namespaces Array of namespaces found in the public/locale/:ns folders
 * @returns {JSX.Element}
 */
export default function MarkdownContent({ namespaces }) {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  useMountEffect(() => {
    i18n.loadNamespaces(namespaces).then(() => setI18NextLoading(false));
  });
  if (i18nextLoading) {
    return (
      <div className="bg-light">
        <div className="main-container">
          <ScreenLoader show />
        </div>
      </div>
    );
  }
  let title = namespaces.map((ns) => loct(`titles:${ns}`) + " | ");
  title = [...title, loct("titles:suma_app")].join("");
  const contentKeys = namespaces.map((namespace) => `${namespace}:contents`);
  return (
    <div className="bg-light">
      <div className="main-container">
        <Helmet>
          <title>{title}</title>
        </Helmet>
        <TopNav />
        {contentKeys.map((key, idx) => (
          <React.Fragment key={key}>
            <LayoutContainer top gutters className="pb-4" style={{ maxWidth: "500px" }}>
              <Row>
                <SumaMarkdown>{i18n.t(key)}</SumaMarkdown>
              </Row>
            </LayoutContainer>
            {idx + 1 !== contentKeys.length && <hr className="my-4" />}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}
