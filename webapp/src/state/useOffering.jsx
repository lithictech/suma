import { OfferingContext } from "./OfferingProvider";
import React from "react";

const useOffering = () => React.useContext(OfferingContext);
export default useOffering;
