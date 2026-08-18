import { t } from "../localization";
import React from "react";
import { Helmet } from "react-helmet-async";

export interface MetatagProps {
  title?: string;
  exact?: boolean;
}

export default function withMetatags({ title, exact }: MetatagProps) {
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
