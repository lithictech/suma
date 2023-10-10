import { t } from "../localization";
import { extractErrorCode } from "./useError";
import { useGlobalViewState } from "./useGlobalViewState";
import React, { useState } from "react";
import Toast from "react-bootstrap/Toast";
import ToastContainer from "react-bootstrap/ToastContainer";

export const ErrorToastContext = React.createContext();

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
export const useErrorToast = () => React.useContext(ErrorToastContext);

export function ErrorToastProvider({ children }) {
  const [state, setState] = useState(null);
  const { appNav, topNav } = useGlobalViewState();
  const navsHeight = (topNav?.clientHeight || 0) + (appNav?.clientHeight || 0);

  React.useEffect(() => {
    const callback = () => {
      setState(null);
    };
    window.addEventListener("popstate", callback);
    return () => window.removeEventListener("popstate", callback);
  }, []);

  const showErrorToast = React.useCallback(
    (e, opts) => {
      if (opts?.extract) {
        e = extractErrorCode(e);
      }
      setState(React.isValidElement(e) ? e : t("errors:" + e));
    },
    [setState]
  );

  const value = React.useMemo(() => ({ showErrorToast }), [showErrorToast]);

  return (
    <ErrorToastContext.Provider value={value}>
      <ToastContainer
        className="d-flex justify-content-center position-fixed p-2 w-100"
        style={{ zIndex: "1021", top: `${navsHeight}px`, left: 0 }}
      >
        <Toast
          show={Boolean(state)}
          autohide={true}
          onClose={() => setState("")}
          bg="light"
        >
          <Toast.Header className="text-danger">
            <i className="bi bi-exclamation-triangle-fill me-2"></i>
            <strong className="me-auto">{t("common:error")}</strong>
          </Toast.Header>
          <Toast.Body>{state}</Toast.Body>
        </Toast>
      </ToastContainer>
      {children}
    </ErrorToastContext.Provider>
  );
}
