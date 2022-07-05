import { makeStyles } from "@mui/styles";

const useGlobalStyles = makeStyles((theme) => ({
  layoutContainer: {
    display: "flex",
    flexGrow: theme.spacing(1),
  },
  layoutMain: {
    marginBottom: theme.spacing(6),
    flexGrow: theme.spacing(1),
    padding: theme.spacing(3),
    width: "100%",
  },
}));

export default useGlobalStyles;
