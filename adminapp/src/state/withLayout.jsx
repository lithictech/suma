import TopNav from "../components/TopNav";
import useGlobalStyles from "../hooks/useGlobalStyles";
import Box from "@mui/material/Box";
import Toolbar from "@mui/material/Toolbar";
import React from "react";
import { useLocation } from "react-router-dom";

// Tracks the last pathname across layout instances (each page is wrapped separately),
// so we only move focus to main content after an in-app navigation, not on first load.
let lastPathname = null;

const skipLinkSx = {
  position: "absolute",
  left: -10000,
  top: 8,
  zIndex: (t) => t.zIndex.tooltip,
  padding: 1,
  backgroundColor: "background.paper",
  color: "text.primary",
  "&:focus": { left: 8 },
};

export default function withLayout() {
  return (Wrapped) => {
    return (props) => {
      const dynamicDrawerWidth = "calc(100% - 250px)";
      const globalClasses = useGlobalStyles();
      const location = useLocation();
      const mainRef = React.useRef(null);
      React.useEffect(() => {
        if (lastPathname !== null && lastPathname !== location.pathname) {
          mainRef.current?.focus({ preventScroll: true });
        }
        lastPathname = location.pathname;
      }, [location.pathname]);
      return (
        <Box className={globalClasses.layoutContainer}>
          <Box
            component="a"
            href="#main"
            className="skip-link print-d-none"
            sx={skipLinkSx}
          >
            Skip to main content
          </Box>
          <TopNav />
          <Box
            component="main"
            id="main"
            tabIndex={-1}
            ref={mainRef}
            sx={{ width: { md: dynamicDrawerWidth }, "&:focus": { outline: "none" } }}
            className={globalClasses.layoutMain}
          >
            <Toolbar className="print-d-none" />
            <Wrapped {...props} />
          </Box>
        </Box>
      );
    };
  };
}
