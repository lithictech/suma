import { ErrorToastContext } from "./ErrorToastProvider";
import React from "react";

/**
 * @typedef ErrorToastState
 * @property {function(*, object=)} showErrorToast Given a string,
 *   popup an error toast using `t(errors:<value>)`.
 *   Given a React element, render it as the toast message verbatim.
 *   Pass showErrorToast(e, {extract: true}) to use `extractErrorCode(e)` as the code.
 */

/**
 * @returns {ErrorToastState}
 */
const useErrorToast = () => React.useContext(ErrorToastContext);
export default useErrorToast;
