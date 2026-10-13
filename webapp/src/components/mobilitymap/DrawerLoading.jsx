import { t } from "../../localization";
import PageLoader from "../PageLoader";
import DrawerContents from "./DrawerContents";
import React from "react";

export default function DrawerLoading() {
  return (
    <DrawerContents>
      <div role="status">
        <PageLoader />
        <span className="visually-hidden">{t("common.loading")}</span>
      </div>
    </DrawerContents>
  );
}
