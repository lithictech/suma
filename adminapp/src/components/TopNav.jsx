import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useNavLinks from "../hooks/useNavLinks";
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
import * as React from "react";

export default function TopNav() {
  const theme = useTheme();
  const openToggle = useToggle(false);
  const isLarge = useMediaQuery(theme.breakpoints.up("md"));
  const dynamicDrawerWidth = `calc(100% - ${drawerWidth}px)`;
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
        className="print-d-none"
        sx={{
          width: { [drawerBP]: dynamicDrawerWidth },
          ml: { [drawerBP]: dynamicDrawerWidth },
        }}
      >
        <Toolbar>
          {!isLarge && (
            <IconButton
              size="large"
              edge="start"
              color="inherit"
              aria-label="menu"
              onClick={openToggle.toggle}
              sx={{ mr: 2, display: { [drawerBP]: "none" } }}
            >
              <MenuIcon />
            </IconButton>
          )}
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Suma Admin
          </Typography>
          <Button color="inherit" onClick={handleLogout}>
            Logout
          </Button>
        </Toolbar>
      </AppBar>
      {isLarge ? (
        <StaticNavDrawer />
      ) : (
        <SlidingNavDrawer open={openToggle.isOn} onClose={openToggle.turnOff} />
      )}
    </>
  );
}

function StaticNavDrawer() {
  const drawerSx = {
    ".MuiDrawer-paper": { width: drawerWidth },
  };
  return (
    <Box
      className="print-d-none"
      component="nav"
      sx={{ width: { [drawerBP]: drawerWidth }, flexShrink: { [drawerBP]: 0 } }}
      aria-label="navigation drawer"
    >
      <Drawer variant="permanent" sx={drawerSx} open>
        <DrawerContents />
      </Drawer>
    </Box>
  );
}

function SlidingNavDrawer({ open, onClose }) {
  const drawerSx = {
    ".MuiDrawer-paper": { width: drawerWidth },
  };
  return (
    <Drawer
      className="print-d-none"
      variant="temporary"
      open={open}
      onClose={onClose}
      ModalProps={{ keepMounted: true }}
      sx={drawerSx}
    >
      <DrawerContents />
    </Drawer>
  );
}

function DrawerContents() {
  const navLinks = useNavLinks();
  return (
    <Box md={{ width: drawerWidth }} role="presentation">
      <Toolbar />
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
}

const drawerBP = "md";
const drawerWidth = 250;
