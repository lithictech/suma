import Money from "../Money";
import clsx from "clsx";
import dayjs from "dayjs";
import i18next from "i18next";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Modal from "react-bootstrap/Modal";

export default function ({ item, onClose }) {
  const { amount, at, opaqueId, usageDetails } = item || {};
  return (
    <Modal show={Boolean(item)} onHide={onClose} onExit={onClose} centered>
      <Modal.Body>
        {!_.isEmpty(item) && (
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
              <p key={i}>{i18next.t(code, { ns: "ledgerusage", ...args })}</p>
            ))}
            <p className="text-secondary mb-1">{dayjs(at).format("LLL")}</p>
            <p className="text-secondary">
              {i18next.t("reference_id", { ns: "common" })}: {opaqueId}
            </p>
            <div className="d-flex justify-content-end mt-4">
              <Button variant="primary" className="mt-2" onClick={onClose}>
                {i18next.t("close", { ns: "common" })}
              </Button>
            </div>
          </>
        )}
      </Modal.Body>
    </Modal>
  );
}