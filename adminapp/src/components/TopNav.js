import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import navLinks from "../modules/navLinks";
import useToggle from "../shared/react/useToggle";
import refreshAsync from "../shared/refreshAsync";
import Link from "./Link";
import CloseIcon from "@mui/icons-material/Close";
import MenuIcon from "@mui/icons-material/Menu";
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
} from "@mui/material";
import AppBar from "@mui/material/AppBar";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import IconButton from "@mui/material/IconButton";
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";
import * as React from "react";

export default function TopNav() {
  const openToggle = useToggle(false);
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const handleLogout = (e) => {
    e.preventDefault();
    api
      .signOut()
      .then(() => refreshAsync())
      .catch(enqueueErrorSnackbar);
  };
  return (
    <Box sx={{ flexGrow: 1 }}>
      <NavDrawer openToggle={openToggle} />
      <AppBar position="static">
        <Toolbar>
          <IconButton
            size="large"
            edge="start"
            color="inherit"
            aria-label="menu"
            onClick={openToggle.toggle}
            sx={{ mr: 2 }}
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
    </Box>
  );
}

function NavDrawer({ openToggle }) {
  return (
    <Drawer
      anchor="left"
      open={openToggle.isOn}
      onClose={openToggle.turnOff}
      onClick={openToggle.turnOff}
    >
      <Box sx={{ width: 250 }} role="presentation">
        <ListItem
          secondaryAction={
            <IconButton edge="end" aria-label="close" onClick={openToggle.turnOff}>
              <CloseIcon />
            </IconButton>
          }
        >
          <ListItemText>&nbsp;</ListItemText>
        </ListItem>
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
    </Drawer>
  );
}
