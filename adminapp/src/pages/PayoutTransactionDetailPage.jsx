import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import DetailGrid from "../components/DetailGrid";
import ExternalLinks from "../components/ExternalLinks";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress } from "@mui/material";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function PayoutTransactionDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getPayoutTransaction = React.useCallback(() => {
    return api.getPayoutTransaction({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: xaction, loading: xactionLoading } = useAsyncFetch(
    getPayoutTransaction,
    {
      default: {},
      pickData: true,
    }
  );

  const { originatedBookTransaction: originated, creditingBookTransaction: crediting } =
    xaction || {};

  return (
    <>
      {xactionLoading && <CircularProgress />}
      {!isEmpty(xaction) && (
        <div>
          <DetailGrid
            title={`Payout Transaction ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(xaction.createdAt) },
              { label: "Status", value: xaction.status },
              { label: "Amount", value: <Money>{xaction.amount}</Money> },
              { label: "Classification", value: xaction.classification },
              { label: "Memo", value: xaction.memo },
            ]}
          />
          <DetailGrid
            title="Originated Book Transaction"
            properties={[
              { label: "ID", value: <AdminLink model={originated} /> },
              { label: "Apply At", value: dayjs(originated.applyAt) },
              { label: "Amount", value: <Money>{originated.amount}</Money> },
              {
                label: "Category",
                value: originated.associatedVendorServiceCategory?.name,
              },
              {
                label: "Originating",
                value: (
                  <AdminLink model={originated.originatingLedger}>
                    {originated.originatingLedger.adminLabel}
                  </AdminLink>
                ),
              },
              {
                label: "Receiving",
                value: (
                  <AdminLink model={originated.receivingLedger}>
                    {originated.receivingLedger.adminLabel}
                  </AdminLink>
                ),
              },
            ]}
          />
          {crediting && (
            <DetailGrid
              title="Crediting Book Transaction"
              properties={[
                { label: "ID", value: <AdminLink model={crediting} /> },
                { label: "Apply At", value: dayjs(crediting.applyAt) },
                { label: "Amount", value: <Money>{crediting.amount}</Money> },
                {
                  label: "Category",
                  value: crediting.associatedVendorServiceCategory?.name,
                },
                {
                  label: "Originating",
                  value: (
                    <AdminLink model={crediting.originatingLedger}>
                      {crediting.originatingLedger.adminLabel}
                    </AdminLink>
                  ),
                },
                {
                  label: "Receiving",
                  value: (
                    <AdminLink model={crediting.receivingLedger}>
                      {crediting.receivingLedger.adminLabel}
                    </AdminLink>
                  ),
                },
              ]}
            />
          )}
          <ExternalLinks externalLinks={xaction.externalLinks} />
          <AuditLogs auditLogs={xaction.auditLogs} />
        </div>
      )}
    </>
  );
}
