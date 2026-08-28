import Drawer from "./Drawer.tsx";

export default function MapWithDrawer({ content, map }) {
  return (
    <div className="position-relative h-100">
      <Drawer>{content}</Drawer>
      {map}
    </div>
  );
}
