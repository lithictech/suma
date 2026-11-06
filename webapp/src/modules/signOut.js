import api from "../api";
import { localStorageCache } from "../shared/localStorageHelper";
import { clearAllFormDrafts } from "../shared/react/useFormDraft";
import refreshAsync from "../shared/refreshAsync";
import { getReadingComfort, setReadingComfort } from "./readingComfort";

export default function signOut() {
  api
    // The member is leaving on purpose, so do not treat a 401 as an interrupted session.
    .authSignout({}, { skipSessionExpired: true })
    .catch((e) => {
      // If the session already ended, the member is signed out; finish cleaning up.
      if (e?.response?.status !== 401) {
        throw e;
      }
    })
    .then(() => {
      // Display preferences belong to the device, not the member, so keep them.
      const readingComfort = getReadingComfort();
      localStorageCache.clear();
      setReadingComfort(readingComfort);
      clearAllFormDrafts();
    })
    .then(refreshAsync);
}
