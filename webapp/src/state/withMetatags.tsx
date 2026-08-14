import { t } from "../localization";
import React from "react";
import { Helmet } from "react-helmet-async";

export default function withMetatags({
  title,
  exact,
}: {
  title?: string;
  exact?: boolean;
}) {
  const customTitle = title ? `${title} | ${t("titles.suma_app")}` : t("titles.suma_app");
  return (Wrapped: React.ComponentType<any>) => {
    return (props: any) => {
      return (
        <>
          <Helmet>
            <title>{exact ? title : customTitle}</title>
          </Helmet>
          <Wrapped {...props} />
        </>
      );
    };
  };
}
