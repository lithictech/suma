import { t } from "../localization";
import { extractErrorCode } from "./useError";
import useGlobalViewState from "./useGlobalViewState";
import React from "react";
import Toast from "react-bootstrap/Toast";
import ToastContainer from "react-bootstrap/ToastContainer";

interface ErrorToastContextValue {
  showErrorToast: (e: any, opts?: { extract?: boolean }) => void;
}

export const ErrorToastContext = React.createContext<ErrorToastContextValue>(
  {} as ErrorToastContextValue
);

export default function ErrorToastProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = React.useState<React.ReactNode>(null);
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
    (e: any, opts?: { extract?: boolean }) => {
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
            <strong className="me-auto">{t("common.error")}</strong>
          </Toast.Header>
          <Toast.Body>{state}</Toast.Body>
        </Toast>
      </ToastContainer>
      {children}
    </ErrorToastContext.Provider>
  );
}
