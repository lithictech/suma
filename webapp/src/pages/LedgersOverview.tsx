import api from "../api.ts";
import TransactionHistory from "../components/TransactionHistory.tsx";
import useAsyncFetch from "../state/useAsyncFetch.ts";
import useListQueryControls from "../state/useListQueryControls.ts";

export default function LedgersOverview() {
  const { params, page, setListQueryParams } = useListQueryControls();
  const ledgerIdParam = Number(params.get("ledger")) || 0;
  const { state, loading, error } = useAsyncFetch<LedgersView>(api.getLedgersOverview);
  return (
    <TransactionHistory
      ledgersOverview={state}
      loading={loading}
      error={error}
      getLedgerLines={api.getLedgerLines}
      ledgerId={ledgerIdParam}
      setLedgerId={(lid) => setListQueryParams({ page: 0 }, { ledger: lid })}
      ledgerLinesPage={page}
      setLedgerLinesPage={(page) => setListQueryParams({ page })}
    />
  );
}
