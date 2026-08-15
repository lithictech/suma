import api from "../api";
import { localStorageCache } from "./localStorageHelper";
import refreshAsync from "./refreshAsync";

export default function signOut() {
  api
    .authSignout()
    .then(() => localStorageCache.clear())
    .then(refreshAsync);
}
