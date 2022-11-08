import api from "../api";
import addIcon from "../assets/images/food-widget-add.svg";
import subtractIcon from "../assets/images/food-widget-subtract.svg";
import { t } from "../localization";
import { useOffering } from "../state/useOffering";
import clsx from "clsx";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import ButtonGroup from "react-bootstrap/ButtonGroup";
import Dropdown from "react-bootstrap/Dropdown";

export default function FoodCartWidget({ product, size }) {
  size = size || "sm";
  const btnClasses = sizeClasses[size];
  const { offering, cart, setCart } = useOffering();

  const changePromise = React.useRef(null);

  const [quantity, setQuantity] = React.useState(() => {
    const item = _.find(cart.items, ({ productId }) => productId === product.productId);
    return item?.quantity || 0;
  });

  const handleQuantityChange = (q) => {
    changePromise.current?.cancel();
    setQuantity(q);
    changePromise.current = api
      .putCartItem({
        offeringId: offering.id,
        productId: product.productId,
        quantity: q,
        timestamp: Date.now(),
      })
      .then((resp) => {
        setCart(resp.data.cart);
      })
      .catch((e) => {
        // TODO: Add an error toast when this fails
        console.error(e);
      });
  };

  // TODO: once we have basic inventory it should control the max quantity
  const maxQuantity = 10;

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
              <DropdownQuantities maxQuantity={maxQuantity} selectedQuantity={quantity} />
            </Dropdown.Menu>
          </Dropdown>
        </>
      )}
      <Button
        variant="success"
        onClick={() => handleQuantityChange(quantity + 1)}
        className={clsx(btnClasses, quantity === maxQuantity && "disabled")}
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
  return _.times(maxQuantity + 1).map((_, i) => (
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
