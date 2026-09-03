import api from "../api.ts";
import PrivateAccountsList from "../components/PrivateAccountsList.tsx";
import useAsyncFetch from "../state/useAsyncFetch.ts";

export default function PrivateAccountsListPage() {
  const { state, loading, error } = useAsyncFetch<{ items: AnonProxyVendorAccount[] }>(
    api.getPrivateAccounts,
    {
      default: { items: [] },
    }
  );
  return <PrivateAccountsList accounts={state.items} loading={loading} error={error} />;
}
