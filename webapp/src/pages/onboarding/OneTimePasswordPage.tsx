import api from "../../api.ts";
import OneTimePassword, { OneTimePasswordApiCalls } from "./OneTimePassword.tsx";

export default function OneTimePasswordPage() {
  return <OneTimePassword apiCalls={apiCalls} />;
}

const apiCalls: OneTimePasswordApiCalls = {
  authVerify: api.authVerify,
  authStart: api.authStart,
};
