import { t } from "../../localization";
import Money from "../../shared/react/Money";
import clsx from "clsx";
import dayjs from "dayjs";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Button from "react-bootstrap/Button";
import Modal from "react-bootstrap/Modal";

export default function ({ item, onClose }) {
  const { amount, at, opaqueId, usageDetails } = item || {};
  return (
    <Modal show={Boolean(item)} onHide={onClose} onExit={onClose} centered>
      <Modal.Body>
        {!isEmpty(item) && (
          <>
            <p className="mt-2 mb-1">
              <Money
                className={clsx(
                  amount.cents < 0 ? "text-danger" : "text-success",
                  "fs-3"
                )}
              >
                {amount}
              </Money>
            </p>
            {usageDetails.map(({ code, args }, i) => (
              <p key={i}>{t("ledgerusage:" + code, { ...args })}</p>
            ))}
            <p className="mb-1">{dayjs(at).format("LLL")}</p>
            <p>
              {t("common:reference_id")}: {opaqueId}
            </p>
            <div className="d-flex justify-content-end mt-4">
              <Button variant="outline-primary" className="mt-2" onClick={onClose}>
                {t("common:close")}
              </Button>
            </div>
          </>
        )}
      </Modal.Body>
    </Modal>
  );
}
