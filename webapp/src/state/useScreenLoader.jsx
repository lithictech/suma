import "../assets/styles/screenloader.scss";
import ScreenLoader from "../components/ScreenLoader";
import useMountEffect from "../shared/react/useMountEffect";
import useToggle from "../shared/react/useToggle";
import React from "react";

export const ScreenLoaderContext = React.createContext();

/**
 * @returns {Toggle}
 */
export const useScreenLoader = () => React.useContext(ScreenLoaderContext);
export function ScreenLoaderProvider({ children }) {
  const toggle = useToggle(false);

  return (
    <ScreenLoaderContext.Provider value={toggle}>
      <ScreenLoader show={toggle.isOn} />
      {children}
    </ScreenLoaderContext.Provider>
  );
}
export function withScreenLoaderMount(show) {
  show = show || false;
  return (Wrapped) => {
    return (props) => {
      const loader = useScreenLoader();
      useMountEffect(() => loader.setState(show));
      return <Wrapped {...props} />;
    };
  };
}
