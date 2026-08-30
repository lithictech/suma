import TODO from "../components/TODO.tsx";

export default function PreferencesAuthed() {
  return <TODO />;
}
//   const { user, setUser } = useUser();
//   const [saved, setSaved] = React.useState(false);
//
//   function handleApiSubmit(prefs: { subscriptions: Record<string, boolean> }) {
//     return api.updatePreferences(prefs);
//   }
//
//   function handleSaved(r: any) {
//     setSaved(true);
//     setUser(r.data);
//   }
//
//   return (
//     <Preferences user={user} onApiSubmit={handleApiSubmit} onSaved={handleSaved}>
//       {saved && (
//         <Alert
//           variant="success"
//           className="mt-4 mb-0"
//           dismissible
//           onClose={() => setSaved(false)}
//         >
//           <FormSuccess message="preferences.success" className="mb-0" />
//         </Alert>
//       )}
//     </Preferences>
//   );
// }
