import FormError from "../../ui/FormError.tsx";

export default function DrawerContentsPageError({ error }) {
  return <FormError noSurface error={error} />;
}
