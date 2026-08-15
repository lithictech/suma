import { ScreenLoaderContext } from "./ScreenLoaderProvider";
import React from "react";

const useScreenLoader = () => React.useContext(ScreenLoaderContext);
export default useScreenLoader;
