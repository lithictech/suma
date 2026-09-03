import api from "../api.ts";
import PrivateAccountDetail, {
  PrivateAccountDetailApiCalls,
} from "../components/PrivateAccountDetail.tsx";
import useUser from "../state/useUser.ts";
import { useParams } from "react-router-dom";

export default function PrivateAccountDetailPage() {
  const { user, setUser } = useUser();
  const { id } = useParams();
  return (
    <PrivateAccountDetail
      id={Number(id)}
      apiCalls={apiCalls}
      user={user!}
      setUser={setUser}
    />
  );
}

const apiCalls: PrivateAccountDetailApiCalls = {
  processAccount: api.processPrivateAccountDetail,
  chargeLedgerBalance: api.chargeLedgerBalance,
  pollForNewPrivateAccountMagicLink: api.pollForNewPrivateAccountMagicLink,
  makeAuthRequest: api.makePrivateAccountAuthRequest,
};
