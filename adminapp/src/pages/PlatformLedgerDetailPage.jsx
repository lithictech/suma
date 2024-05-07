import api from "../api";
import DetailGrid from "../components/DetailGrid";
import LedgerBookTransactionsRelatedList from "../components/LedgerBookTransactionRelatedList";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
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
          <LedgerBookTransactionsRelatedList
            ledger={ledger}
            title="Book Transactions"
            rows={ledger.combinedBookTransactions}
          />
        </>
      )}
    </>
  );
}
