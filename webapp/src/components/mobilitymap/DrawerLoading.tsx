import PageLoader from "../PageLoader";
import DrawerContents from "./DrawerContents";
import React from "react";

export default function DrawerLoading() {
  return (
    <DrawerContents>
      <PageLoader />
    </DrawerContents>
  );
}
