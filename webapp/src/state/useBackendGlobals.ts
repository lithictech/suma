import { BackendGlobalsContext } from "./BackendGlobalsProvider";
import React from "react";

const useBackendGlobals = () => React.useContext(BackendGlobalsContext);
export default useBackendGlobals;
