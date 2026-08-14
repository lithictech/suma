import { GlobalViewStateContext } from "./GlobalViewStateProvider";
import React from "react";

/**
 * @typedef GlobalViewState
 * @property {Element=} topNav The element with the logo and hamburger.
 * @property {function(Element=): void} setTopNav
 * @property {Element=} appNav The element with the tab sections (home, mobility, etc).
 * @property {function(Element=): void} setTopNav
 */

/**
 * Global view state manages global state about the view,
 * like the DOM elements for navigation.
 * @returns {GlobalViewState}
 */
const useGlobalViewState = () => React.useContext(GlobalViewStateContext);
export default useGlobalViewState;
