import api from "../api";
import { updateCanPromptCache } from "../components/AddToHomescreen";
import { localStorageCache } from "../shared/localStorageHelper";
import refreshAsync from "../shared/refreshAsync";

export default function signOut() {
  api
    .authSignout()
    .then(() => {
      localStorageCache.clear();
      updateCanPromptCache();
    })
    .then(refreshAsync);
}
