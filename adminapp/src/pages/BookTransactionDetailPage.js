import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress } from "@mui/material";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function BookTransactionDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getBookTransaction = React.useCallback(() => {
    return api
      .getBookTransaction({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: xaction, loading: xactionLoading } = useAsyncFetch(getBookTransaction, {
    default: {},
    pickData: true,
  });

  return (
    <>
      {xactionLoading && <CircularProgress />}
      {!isEmpty(xaction) && (
        <div>
          <DetailGrid
            title={`Book Transaction ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Apply At", value: dayjs(xaction.applyAt) },
              { label: "Amount", value: <Money>{xaction.amount}</Money> },
              { label: "Category", value: xaction.associatedVendorServiceCategory.name },
              { label: "External Id", value: xaction.opaqueId },
              { label: "Memo", value: xaction.memo },
              {
                label: "Originating",
                value: (
                  <AdminLink model={xaction.originatingLedger}>
                    {xaction.originatingLedger.adminLabel}
                  </AdminLink>
                ),
              },
              {
                label: "Receiving",
                value: (
                  <AdminLink model={xaction.receivingLedger}>
                    {xaction.receivingLedger.adminLabel}
                  </AdminLink>
                ),
              },
            ]}
          />
          <RelatedList
            title="Funding Transactions"
            rows={xaction.fundingTransactions}
            headers={["Id", "Created", "Status", "Amount"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.status,
              <Money key="amt">{row.amount}</Money>,
            ]}
          />
          <RelatedList
            title="Charges"
            headers={["Id", "At", "Undiscounted Total", "Opaque Id"]}
            rows={xaction.charges}
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              <Money key={3}>{row.undiscountedSubtotal}</Money>,
              row.opaqueId,
            ]}
          />
        </div>
      )}
    </>
  );
}
