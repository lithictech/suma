import "../assets/styles/screenloader.scss";
import ScreenLoader from "../components/ScreenLoader";
import useToggle from "../shared/react/useToggle";
import React from "react";

export const ScreenLoaderContext = React.createContext({});

export default function ScreenLoaderProvider({ children }) {
  const toggle = useToggle(false);

  return (
    <ScreenLoaderContext.Provider value={toggle}>
      <ScreenLoader show={toggle.isOn} />
      {children}
    </ScreenLoaderContext.Provider>
  );
}
