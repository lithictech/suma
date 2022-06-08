import Money from "../Money";
import clsx from "clsx";
import dayjs from "dayjs";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Modal from "react-bootstrap/Modal";

const LedgerItemModal = ({ item, show, onClose, onExited }) => {
  if (_.isEmpty(item)) {
    return null;
  }
  const { amount, at, mobility, memo, opaqueId } = item;
  return (
    <>
      <Modal
        show={show}
        onHide={onClose}
        onExited={onExited}
        aria-labelledby="contained-modal-title-vcenter"
        centered
      >
        <Modal.Body>
          {!_.isEmpty(item) && (
            <>
              <div className="p-2 mb-4 text-center">
                <p className="my-1">
                  <Money
                    className={clsx(
                      amount.cents < 0 ? "text-danger" : "text-success",
                      "fs-3"
                    )}
                  >
                    {amount}
                  </Money>
                </p>
                <p className="m-0">{memo}</p>
                <p className="m-0 text-secondary">{dayjs(at).format("LLL")}</p>
              </div>
              {!_.isEmpty(mobility) && (
                <>
                  <hr />
                  <div className="mt-2">
                    <h5 className="mb-2 text-center">Mobility Trip</h5>
                    <div className="hstack gap-4">
                      <div>
                        <p className="m-0">
                          <strong>Started:</strong>
                        </p>
                        <p className="m-0">{dayjs(mobility.startedAt).format("lll")}</p>
                      </div>
                      <div className="ms-auto text-end">
                        <p className="m-0">
                          <strong>Ended:</strong>
                        </p>
                        <p className="m-0">{dayjs(mobility.endedAt).format("lll")}</p>
                      </div>
                    </div>
                  </div>
                </>
              )}
              <hr />
              <p className="text-secondary">
                <strong>Transaction Ref:</strong> {opaqueId}
              </p>
              <div className="d-flex justify-content-end mt-4">
                <Button variant="primary" className="mt-2" onClick={onClose}>
                  Close
                </Button>
              </div>
            </>
          )}
        </Modal.Body>
      </Modal>
    </>
  );
};

export default LedgerItemModal;
