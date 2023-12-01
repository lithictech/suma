import { I18NextContext } from "./I18NextProvider";
import React from "react";

export const useI18Next = () => React.useContext(I18NextContext);
export default useI18Next;
