import api from "../api";
import addIcon from "../assets/images/food-widget-add.svg";
import subtractIcon from "../assets/images/food-widget-subtract.svg";
import xIcon from "../assets/images/ui-x-thick.svg";
import { t } from "../localization";
import useErrorToast from "../state/useErrorToast";
import useOffering from "../state/useOffering";
import Button from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Dropdown from "../ui/Dropdown";
import SoldOutText from "./SoldOutText";
import clsx from "clsx";
import find from "lodash/find";
import noop from "lodash/noop";
import times from "lodash/times";
import React from "react";

interface FoodCartWidgetProps {
  product: PricedOfferingProduct;
  size?: "sm" | "lg";
  onQuantityChange?: (q: number) => void;
}

export default function FoodCartWidget({
  product,
  size,
  onQuantityChange,
}: FoodCartWidgetProps) {
  size = size || "sm";
  const btnClasses = sizeClasses[size];
  const { offering, cart, setOfferingFromResponse } = useOffering();
  const { showErrorToast } = useErrorToast();

  const changeAbortController = React.useRef(new AbortController());
  const [quantity, setQuantity] = React.useState(() => {
    const item = find(cart.items, ({ productId }) => productId === product.productId);
    return item?.quantity || 0;
  });
  const handleQuantityChange = (q: number) => {
    if (q === quantity) {
      return;
    }
    changeAbortController.current?.abort();
    const thisAbortCtrl = new AbortController();
    changeAbortController.current = thisAbortCtrl;
    api
      .putCartItem({
        offeringId: offering.id,
        productId: product.productId,
        quantity: q,
        timestamp: Date.now(),
      })
      .then(api.pickData)
      .then((data: any) => {
        if (thisAbortCtrl.signal.aborted) {
          return;
        }
        setOfferingFromResponse(data);
        setQuantity(q);
        if (onQuantityChange) {
          onQuantityChange(q);
        }
      })
      .catch((e: any) => showErrorToast(e, { extract: true }));
  };

  if (product.outOfStock) {
    return (
      <ButtonGroup aria-label="add-to-cart" className="shadow">
        <Button
          variant="secondary"
          className={clsx(
            btnClasses,
            size === "sm" && "p-1",
            size === "lg" && "p-2",
            "text-nowrap"
          )}
          disabled={quantity === 0}
          onClick={quantity > 0 ? () => handleQuantityChange(0) : noop}
        >
          <span className="text-capitalize fs-5 align-middle mx-1">
            <SoldOutText cart={cart} product={product} />
          </span>
          {quantity > 0 && (
            <img
              src={xIcon}
              alt={t("food.remove_from_cart")}
              width="20px"
              className="ms-1"
            />
          )}
        </Button>
      </ButtonGroup>
    );
  }

  const maxQuantity = Math.min(MAX_DISPLAYABLE_QUANTITY, product.maxQuantity);
  return (
    <ButtonGroup aria-label="add-to-cart" className="shadow">
      {quantity > 0 && (
        <>
          <Button
            onClick={() => handleQuantityChange(quantity - 1)}
            className={btnClasses}
            title={t("food.remove_from_cart")}
          >
            <img src={subtractIcon} alt={t("food.remove_from_cart")} width="32px" />
          </Button>
          <Dropdown
            as={ButtonGroup}
            title={"" + quantity}
            onSelect={(quantity) => handleQuantityChange(Number(quantity))}
          >
            <>
              <Dropdown.Toggle className="py-0 px-2" style={{ width: 60 }}>
                {quantity}
              </Dropdown.Toggle>
              <Dropdown.Menu className="food-widget-dropdown-menu" renderOnMount={true}>
                <DropdownQuantities
                  maxQuantity={maxQuantity}
                  selectedQuantity={quantity}
                />
              </Dropdown.Menu>
            </>
          </Dropdown>
        </>
      )}
      <Button
        onClick={() => handleQuantityChange(quantity + 1)}
        className={clsx(
          btnClasses,
          quantity === maxQuantity && "disabled",
          "text-nowrap"
        )}
        title={t("food.add_to_cart")}
      >
        <img src={addIcon} alt={t("food.add_to_cart")} width="32px" />
        {size === "lg" && quantity === 0 && (
          <span
            className="text-capitalize fs-5 align-middle ms-1 pe-2"
            // Image always has alt text, do not have screen readers read it twice
            aria-hidden="true"
          >
            {t("food.add_to_cart")}
          </span>
        )}
      </Button>
    </ButtonGroup>
  );
}

const DropdownQuantities = ({
  maxQuantity,
  selectedQuantity,
}: {
  maxQuantity: number;
  selectedQuantity: number;
}) => {
  return times(maxQuantity + 1).map((_, i) => (
    <Dropdown.Item
      key={i}
      eventKey={i}
      className={clsx(i === selectedQuantity && "active")}
    >
      {i}
    </Dropdown.Item>
  ));
};

const sizeClasses: Record<string, string> = {
  lg: "lh-1 m-0 p-2",
  sm: "lh-1 m-0 p-0",
};

const MAX_DISPLAYABLE_QUANTITY = 15;
