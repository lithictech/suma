import { t } from "../localization";
import Button from "../ui/Button";
import Toast from "../ui/Toast";
import ToastBody from "../ui/ToastBody";
import ToastContainer from "../ui/ToastContainer";
import clsx from "clsx";
import isNumber from "lodash/isNumber";
import React from "react";

interface CopyableProps {
  className?: string;
  children?: React.ReactNode;
  delay?: number;
  inline?: boolean;
  text?: string;
}

export default function Copyable({
  className,
  children,
  delay,
  inline,
  text,
}: CopyableProps) {
  delay = isNumber(delay) ? delay : 2000;
  const [toastShow, setToastShow] = React.useState(false);
  function onCopy(e: React.MouseEvent) {
    e.preventDefault();
    navigator.clipboard.writeText(text || (children as string));
    setToastShow(true);
  }
  return (
    <>
      <div className={clsx(inline && "d-inline text-nowrap", className)}>
        {children || text}
        <Button variant="text" className={clsx(inline && "p-0 ps-2")} onClick={onCopy}>
          <i className="bi bi-clipboard2-fill"></i>
        </Button>
      </div>

      <ToastContainer className="p-3" position="top-end" style={{ zIndex: 10 }}>
        <Toast
          bg="success"
          onClose={() => setToastShow(false)}
          show={toastShow}
          delay={delay}
          autohide
        >
          <ToastBody>
            <p className="lead text-light mb-0">{t("common.copied_to_clipboard")}</p>
          </ToastBody>
        </Toast>
      </ToastContainer>
    </>
  );
}
