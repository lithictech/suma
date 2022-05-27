import { makeStyles } from "@mui/styles";

const useStyles = makeStyles((theme) => ({
  root: {
    marginTop: theme.spacing(5),
  },
  row: {
    display: "flex",
    flexDirection: "row",
  },
}));

export default useStyles;
