import api from "../api";
import addIcon from "../assets/images/food-widget-add.svg";
import subtractIcon from "../assets/images/food-widget-subtract.svg";
import xIcon from "../assets/images/ui-x-thick.svg";
import { t } from "../localization";
import { useErrorToast } from "../state/useErrorToast";
import { useOffering } from "../state/useOffering";
import clsx from "clsx";
import find from "lodash/find";
import noop from "lodash/noop";
import times from "lodash/times";
import React from "react";
import Button from "react-bootstrap/Button";
import ButtonGroup from "react-bootstrap/ButtonGroup";
import Dropdown from "react-bootstrap/Dropdown";

export default function FoodCartWidget({ product, size, onQuantityChange }) {
  size = size || "sm";
  const btnClasses = sizeClasses[size];
  const { offering, cart, setCart } = useOffering();
  const { showErrorToast } = useErrorToast();

  const changePromise = React.useRef(null);

  const [quantity, setQuantity] = React.useState(() => {
    const item = find(cart.items, ({ productId }) => productId === product.productId);
    return item?.quantity || 0;
  });

  const handleQuantityChange = (q) => {
    changePromise.current?.cancel();
    changePromise.current = api
      .putCartItem({
        offeringId: offering.id,
        productId: product.productId,
        quantity: q,
        timestamp: Date.now(),
      })
      .then(api.pickData)
      .then((cart) => {
        setCart(cart);
        setQuantity(q);
        if (onQuantityChange) {
          onQuantityChange(q);
        }
      })
      .catch((e) => showErrorToast(e, { extract: true }));
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
            "nowrap"
          )}
          disabled={quantity === 0}
          onClick={quantity > 0 ? () => handleQuantityChange(0) : noop}
        >
          <span className="text-capitalize fs-5 align-middle mx-1">
            {t("food:out_of_stock")}
          </span>
          {quantity > 0 && (
            <img
              src={xIcon}
              alt={t("food:remove_from_cart")}
              width="20px"
              className="ms-1"
            />
          )}
        </Button>
      </ButtonGroup>
    );
  }

  return (
    <ButtonGroup aria-label="add-to-cart" className="shadow">
      {quantity > 0 && (
        <>
          <Button
            variant="success"
            onClick={() => handleQuantityChange(quantity - 1)}
            className={btnClasses}
            title={t("food:remove_from_cart")}
          >
            <img src={subtractIcon} alt={t("food:remove_from_cart")} width="32px" />
          </Button>
          <Dropdown
            variant="success"
            as={ButtonGroup}
            title={"" + quantity}
            onSelect={(quantity) => handleQuantityChange(Number(quantity))}
          >
            <Dropdown.Toggle
              variant="success"
              className="py-0 px-2"
              style={{ width: 60 }}
            >
              {quantity}
            </Dropdown.Toggle>
            <Dropdown.Menu className="food-widget-dropdown-menu" renderOnMount={true}>
              <DropdownQuantities
                maxQuantity={product.maxQuantity}
                selectedQuantity={quantity}
              />
            </Dropdown.Menu>
          </Dropdown>
        </>
      )}
      <Button
        variant="success"
        onClick={() => handleQuantityChange(quantity + 1)}
        className={clsx(
          btnClasses,
          quantity === product.maxQuantity && "disabled",
          "nowrap"
        )}
        title={t("food:add_to_cart")}
      >
        <img src={addIcon} alt={t("food:add_to_cart")} width="32px" />
        {size === "lg" && quantity === 0 && (
          <span className="text-capitalize fs-5 align-middle ms-1 pe-2">
            {t("food:add_to_cart")}
          </span>
        )}
      </Button>
    </ButtonGroup>
  );
}

const DropdownQuantities = ({ maxQuantity, selectedQuantity }) => {
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

const sizeClasses = {
  lg: "lh-1 m-0 p-2",
  sm: "lh-1 m-0 p-0",
};
