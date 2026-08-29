import config from "../config";
import { t } from "../localization";
import Button from "../ui/Button";

export default function AddFundsLinkButton() {
  if (!config.featureAddFunds) {
    return null;
  }
  return (
    <Button variant="outline" to="/funding" size="sm">
      {t("payments.add_funds")}
    </Button>
  );
}
