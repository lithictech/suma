import { t } from "../localization";

export default function SoldOutText({ cart, product }) {
  if (!product.outOfStock) {
    return null;
  }
  if (cart.cartFull) {
    return t("food.cart_full");
  }
  return t("food.sold_out");
}
