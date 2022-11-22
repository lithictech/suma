import { t } from "../localization";
import { useError } from "./useError";
import { useGlobalViewState } from "./useGlobalViewState";
import React from "react";
import Toast from "react-bootstrap/Toast";
import ToastContainer from "react-bootstrap/ToastContainer";

export const ErrorToastContext = React.createContext();
export const useErrorToast = () => React.useContext(ErrorToastContext);
export function ErrorToastProvider({ children }) {
  const [errorToast, setErrorToast] = useError("");
  const { appNav, topNav } = useGlobalViewState();
  const navsHeight = (topNav?.clientHeight || 0) + (appNav?.clientHeight || 0);
  return (
    <ErrorToastContext.Provider value={{ setErrorToast }}>
      <ToastContainer
        className="d-flex justify-content-center position-fixed p-2 w-100"
        style={{ zIndex: "1021", top: `${navsHeight}px`, left: 0 }}
      >
        <Toast
          show={Boolean(errorToast)}
          autohide={true}
          onClose={() => setErrorToast("")}
          bg="light"
        >
          <Toast.Header className="text-danger">
            <i className="bi bi-exclamation-triangle-fill me-2"></i>
            <strong className="me-auto">{t("common:error")}</strong>
          </Toast.Header>
          <Toast.Body>{errorToast}</Toast.Body>
        </Toast>
      </ToastContainer>
      {children}
    </ErrorToastContext.Provider>
  );
}
