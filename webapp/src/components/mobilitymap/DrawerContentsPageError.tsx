import FormError, { FormErrorError } from "../../ui/FormError.tsx";

export default function DrawerContentsPageError({ error }: { error: FormErrorError }) {
  return <FormError noSurface error={error} />;
}
