import { t } from "../localization";

interface SoldOutTextProps {
  cart: Cart;
  product: PricedOfferingProduct;
}

export default function SoldOutText({ cart, product }: SoldOutTextProps) {
  if (!product.outOfStock) {
    return null;
  }
  if (cart.cartFull) {
    return t("food.cart_full");
  }
  return product.outOfStockReasonText;
}
