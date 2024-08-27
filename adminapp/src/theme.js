import { createTheme } from "@mui/material";

let theme = createTheme({
  palette: {
    primary: { main: "#CDA671FF" },
    secondary: { main: "#848682FF" },
    success: { main: "#498567" },
    error: { main: "#b53d00" },
  },
});

theme = createTheme(theme, {
  // Custom colors created with augmentColor go here
  palette: {
    muted: theme.palette.augmentColor({
      color: {
        main: "#b6b6b6",
      },
      name: "muted",
    }),
  },
});

export default theme;
