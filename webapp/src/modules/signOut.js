import api from "../api";
import { localStorageCache } from "../shared/localStorageHelper";
import refreshAsync from "../shared/refreshAsync";

export default function signOut() {
  api
    .authSignout()
    .then(() => localStorageCache.clear())
    .then(refreshAsync);
}
