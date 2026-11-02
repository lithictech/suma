import api from "../api";
import Alert from "../components/Alert";
import FormSuccess from "../components/FormSuccess";
import Preferences from "../components/Preferences";
import useUser from "../state/useUser";
import React from "react";

export default function PreferencesAuthed() {
  const { user, setUser } = useUser();
  const [saved, setSaved] = React.useState(false);

  function handleApiSubmit(prefs) {
    return api.updatePreferences(prefs);
  }

  function handleSaved(r) {
    setSaved(true);
    setUser(r.data);
  }

  return (
    <Preferences user={user} onApiSubmit={handleApiSubmit} onSaved={handleSaved}>
      {saved && (
        <Alert
          variant="success"
          className="mt-4 mb-0"
          dismissible
          onClose={() => setSaved(false)}
        >
          <FormSuccess message="preferences.success" className="mb-0" />
        </Alert>
      )}
    </Preferences>
  );
}
