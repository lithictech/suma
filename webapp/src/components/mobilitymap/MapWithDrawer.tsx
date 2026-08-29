import Drawer from "./Drawer.tsx";
import React from "react";

interface MapWithDrawerProps {
  content: React.ReactNode;
  map: React.ReactNode;
}

export default function MapWithDrawer({ content, map }: MapWithDrawerProps) {
  return (
    <div className="position-relative h-100">
      <Drawer>{content}</Drawer>
      {map}
    </div>
  );
}
