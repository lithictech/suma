import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import { scaleMoney } from "../shared/money";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress } from "@mui/material";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function PlatformLedgerDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getPlatformLedger = React.useCallback(() => {
    return api.getPlatformLedger({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: ledger, loading: ledgerLoading } = useAsyncFetch(getPlatformLedger, {
    default: {},
    pickData: true,
  });

  return (
    <>
      {ledgerLoading && <CircularProgress />}
      {!isEmpty(ledger) && (
        <>
          <DetailGrid
            title={`Platform Ledger ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(ledger.createdAt) },
              { label: "Name", value: ledger.label },
              { label: "Currency", value: ledger.currency },
              { label: "Balance", value: <Money>{ledger.balance}</Money> },
            ]}
          />
          <RelatedList
            title="Vendor Service Categories"
            headers={["Id", "Name", "Slug"]}
            rows={ledger.vendorServiceCategories}
            keyRowAttr="id"
            toCells={(row) => [row.id, row.name, row.slug]}
          />
          <RelatedList
            title="Book Transactions"
            headers={[
              "Id",
              "Created",
              "Applied",
              "Amount",
              "Category",
              "Originating",
              "Receiving",
            ]}
            rows={ledger.combinedBookTransactions}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              dayjs(row.applyAt).format("lll"),
              <Money key="amt" accounting>
                {row.originatingLedger.id === ledger.id
                  ? scaleMoney(row.amount, -1)
                  : row.amount}
              </Money>,
              row.associatedVendorServiceCategory?.name,
              <AdminLink key="originating" model={row.originatingLedger}>
                {row.originatingLedger.adminLabel}
              </AdminLink>,
              <AdminLink key="receiving" model={row.receivingLedger}>
                {row.receivingLedger.adminLabel}
              </AdminLink>,
            ]}
          />
        </>
      )}
    </>
  );
}
