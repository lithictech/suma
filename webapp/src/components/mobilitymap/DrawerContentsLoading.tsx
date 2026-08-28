import Stack from "../../ui/Stack.tsx";
import PageLoader from "../PageLoader";
import DrawerContents from "./DrawerContents";

export default function DrawerContentsLoading() {
  return (
    <DrawerContents>
      <Stack col center>
        <PageLoader height={100} />
      </Stack>
    </DrawerContents>
  );
}
