import IndeterminateLoader from "../../ui/IndeterminateLoader.tsx";
import Stack from "../../ui/Stack.tsx";
import DrawerContents from "./DrawerContents";

export default function DrawerContentsLoading() {
  return (
    <DrawerContents>
      <Stack col center className="position-relative">
        <IndeterminateLoader size={100} variant="plain" />
      </Stack>
    </DrawerContents>
  );
}
