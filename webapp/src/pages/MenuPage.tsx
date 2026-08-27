import api from "../api";
import AddToHomescreen from "../components/AddToHomescreen";
import AppNav from "../components/AppNav.tsx";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import ProgramCard from "../components/ProgramCard.tsx";
import SeeAlsoAlert from "../components/SeeAlsoAlert";
import { t } from "../localization";
import readOnlyReason from "../modules/readOnlyReason";
import useAsyncFetch from "../state/useAsyncFetch";
import useUser from "../state/useUser";
import Alert from "../ui/Alert";
import Page from "../ui/Page.tsx";
import Stack from "../ui/Stack";
import { Link } from "react-router-dom";

export default function MenuPage() {
  return (
    <Page>
      <Page buffer>Yo</Page>
      <AppNav />
    </Page>
  );
}
