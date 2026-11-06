import ToastHeader from "../components/ToastHeader";
import { t } from "../localization";
import { extractErrorCode } from "./useError";
import React from "react";
import Toast from "react-bootstrap/Toast";
import ToastContainer from "react-bootstrap/ToastContainer";

export const ErrorToastContext = React.createContext({});

export default function ErrorToastProvider({ children }) {
  const [state, setState] = React.useState(null);
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
      setState(React.isValidElement(e) ? e : t("errors." + e));
    },
    [setState]
  );

  const value = React.useMemo(() => ({ showErrorToast }), [showErrorToast]);

  return (
    <ErrorToastContext.Provider value={value}>
      <ToastContainer
        className="d-flex justify-content-center position-fixed p-2 w-100"
        // Anchored to the bottom (above the safe area) so the toast never covers
        // focused content under the sticky navs (2.4.11 Focus Not Obscured).
        style={{
          zIndex: "1021",
          bottom: "max(16px, env(safe-area-inset-bottom))",
          left: 0,
        }}
      >
        <Toast
          show={Boolean(state)}
          autohide={false}
          onClose={() => setState("")}
          bg="light"
        >
          <ToastHeader className="text-danger">
            <i className="bi bi-exclamation-triangle-fill me-2" aria-hidden="true"></i>
            <strong className="me-auto">{t("common.error")}</strong>
          </ToastHeader>
          <Toast.Body>{state}</Toast.Body>
        </Toast>
      </ToastContainer>
      {children}
    </ErrorToastContext.Provider>
  );
}
