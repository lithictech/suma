import { t } from "../../localization";
import Money from "../../shared/react/Money";
import Button from "../../ui/Button";
import Modal from "../../ui/Modal";
import ModalBody from "../../ui/ModalBody";
import clsx from "clsx";
import dayjs from "dayjs";
import isEmpty from "lodash/isEmpty";
import React from "react";

interface LedgerItemModalProps {
  item: LedgerLine | null;
  onClose: () => void;
}

export default function LedgerItemModal({ item, onClose }: LedgerItemModalProps) {
  const { amount, at, opaqueId, usageDetails } = item || ({} as LedgerLine);
  return (
    <Modal show={Boolean(item)} onHide={onClose} onExit={onClose} centered>
      <ModalBody>
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
              <p key={i}>{t("ledgerusage." + code, { ...args })}</p>
            ))}
            <p className="mb-1">{dayjs(at).format("LLL")}</p>
            <p>
              {t("common.reference_id")}: {opaqueId}
            </p>
            <div className="d-flex justify-content-end mt-4">
              <Button variant="primary" className="mt-2" onClick={onClose}>
                {t("common.close")}
              </Button>
            </div>
          </>
        )}
      </ModalBody>
    </Modal>
  );
}
