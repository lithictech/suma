import ScreenLoader from "../components/ScreenLoader";
import useToggle, { Toggle } from "../shared/react/useToggle";
import React from "react";

export const ScreenLoaderContext = React.createContext<Toggle>({} as Toggle);

export default function ScreenLoaderProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const toggle = useToggle(false);

  return (
    <ScreenLoaderContext.Provider value={toggle}>
      <ScreenLoader show={toggle.isOn} />
      {children}
    </ScreenLoaderContext.Provider>
  );
}
