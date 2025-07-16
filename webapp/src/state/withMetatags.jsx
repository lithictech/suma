import "../assets/styles/screenloader.scss";
import { t } from "../localization";
import React from "react";
import { Helmet } from "react-helmet-async";

export default function withMetatags({ title, exact }) {
  const customTitle = title ? `${title} | ${t("titles.suma_app")}` : t("titles.suma_app");
  return (Wrapped) => {
    return (props) => {
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
