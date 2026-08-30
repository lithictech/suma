import { t } from "../localization";
import Button from "../ui/Button";

export default function GoHome() {
  return (
    <Button size="lg" to="/dashboard">
      {t("common.go_home")}
    </Button>
  );
}
