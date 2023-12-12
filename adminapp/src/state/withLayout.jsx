import TopNav from "../components/TopNav";
import useGlobalStyles from "../hooks/useGlobalStyles";
import Box from "@mui/material/Box";
import Toolbar from "@mui/material/Toolbar";
import React from "react";

export default function withLayout() {
  return (Wrapped) => {
    return (props) => {
      const dynamicDrawerWidth = "calc(100% - 250px)";
      const globalClasses = useGlobalStyles();
      return (
        <Box className={globalClasses.layoutContainer}>
          <TopNav />
          <Box
            component="main"
            sx={{ width: { md: dynamicDrawerWidth } }}
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
