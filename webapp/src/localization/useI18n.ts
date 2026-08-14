import { I18nContext } from "./I18nProvider";
import React from "react";

export const useI18n = () => React.useContext(I18nContext);
export default useI18n;
