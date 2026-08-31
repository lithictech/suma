import api from "../api";
import AddToHomescreen from "../components/AddToHomescreen";
import Dashboard from "../components/Dashboard.tsx";
import useAsyncFetch from "../state/useAsyncFetch";
import useUser from "../state/useUser.ts";
import Page from "../ui/Page.tsx";

export default function DashboardPage() {
  const { state, loading, error } = useAsyncFetch<Dashboard>(api.dashboard, {
    default: {} as Dashboard,
  });
  const { user } = useUser();
  return (
    <Page appNav>
      <AddToHomescreen />
      <Dashboard user={user!} dashboard={state} loading={loading} error={error} />
    </Page>
  );
}
