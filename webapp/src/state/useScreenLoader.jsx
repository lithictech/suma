import "../assets/styles/screenloader.scss";
import { ScreenLoaderContext } from "./ScreenLoaderProvider";
import React from "react";

/**
 * @returns {Toggle}
 */
const useScreenLoader = () => React.useContext(ScreenLoaderContext);
export default useScreenLoader;
