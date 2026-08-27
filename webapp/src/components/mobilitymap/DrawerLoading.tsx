import PageLoader from "../PageLoader";
import DrawerContents from "./DrawerContents";

export default function DrawerLoading() {
  return (
    <DrawerContents>
      <PageLoader />
    </DrawerContents>
  );
}
