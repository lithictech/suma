import api from "../../api.ts";
import Start, { StartApiCalls } from "./Start.tsx";

export default function StartPage() {
  return <Start apiCalls={apiCalls} />;
}

const apiCalls: StartApiCalls = {
  authStart: api.authStart,
};
