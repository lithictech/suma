import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import navLinks from "../modules/navLinks";
import useToggle from "../shared/react/useToggle";
import refreshAsync from "../shared/refreshAsync";
import Link from "./Link";
import MenuIcon from "@mui/icons-material/Menu";
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  useMediaQuery,
} from "@mui/material";
import AppBar from "@mui/material/AppBar";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Divider from "@mui/material/Divider";
import IconButton from "@mui/material/IconButton";
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";
import { useTheme } from "@mui/styles";
import clsx from "clsx";
import * as React from "react";

export default function TopNav() {
  const openToggle = useToggle(false);
  const dynamicDrawerWidth = "calc(100% - 250px)";
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const handleLogout = (e) => {
    e.preventDefault();
    api
      .signOut()
      .then(() => refreshAsync())
      .catch(enqueueErrorSnackbar);
  };
  return (
    <>
      <AppBar
        position="fixed"
        sx={{
          width: { md: dynamicDrawerWidth },
          ml: { md: dynamicDrawerWidth },
        }}
      >
        <Toolbar>
          <IconButton
            size="large"
            edge="start"
            color="inherit"
            aria-label="menu"
            onClick={openToggle.toggle}
            sx={{ mr: 2, display: { md: "none" } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Suma Admin
          </Typography>
          <Button color="inherit" onClick={handleLogout}>
            Logout
          </Button>
        </Toolbar>
      </AppBar>
      <NavDrawer openToggle={openToggle} />
    </>
  );
}

function NavDrawer({ openToggle }) {
  const drawerWidth = 250;
  const drawer = (
    <Box md={{ width: drawerWidth }} role="presentation">
      <Toolbar>
        <Typography variant="h6">Navigation</Typography>
      </Toolbar>
      <Divider />
      <List>
        {navLinks.map(({ label, href, icon }) => (
          <ListItem key={label} disablePadding>
            <ListItemButton component={Link} href={href}>
              <ListItemIcon>{icon}</ListItemIcon>
              <ListItemText primary={label} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </Box>
  );
  const theme = useTheme();
  const isMediumSize = useMediaQuery(theme.breakpoints.down("md"));
  const drawerSx = {
    display: {
      sm: clsx(isMediumSize ? "block" : "none"),
      md: clsx(isMediumSize ? "none" : "block"),
    },
    "& .MuiDrawer-paper": { boxSizing: "border-box", width: drawerWidth },
  };
  return (
    <Box
      component="nav"
      sx={{ width: { md: drawerWidth }, flexShrink: { md: 0 } }}
      aria-label="navigation drawer"
    >
      {isMediumSize ? (
        <Drawer
          variant="temporary"
          open={openToggle.isOn}
          onClose={openToggle.turnOff}
          ModalProps={{
            // Better open performance on mobile
            keepMounted: true,
          }}
          sx={drawerSx}
        >
          {drawer}
        </Drawer>
      ) : (
        <Drawer variant="permanent" sx={drawerSx} open>
          {drawer}
        </Drawer>
      )}
    </Box>
  );
}
