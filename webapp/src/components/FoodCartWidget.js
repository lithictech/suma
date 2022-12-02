import api from "../api";
import addIcon from "../assets/images/food-widget-add.svg";
import subtractIcon from "../assets/images/food-widget-subtract.svg";
import { t } from "../localization";
import { useErrorToast } from "../state/useErrorToast";
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
  const { showErrorToast } = useErrorToast();

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
        setCart(resp.data);
      })
      .catch((e) => showErrorToast(e, { extract: true }));
  };

  return (
    <ButtonGroup aria-label="add-to-cart" className="shadow">
      {quantity > 0 && !outOfStock && (
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
            title={quantity}
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
      {!outOfStock ? (
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
            <span className="text-capitalize fs-5 align-middle mx-1">
              {t("food:add_to_cart")}
            </span>
          )}
        </Button>
      ) : (
        <Button
          variant="secondary"
          className={clsx(btnClasses, size === "sm" && "px-1 pb-1", "disabled nowrap")}
        >
          <span className="text-capitalize fs-5 align-middle mx-1">
            {t("food:out_of_stock")}
          </span>
        </Button>
      )}
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

// TODO: Return/expose outOfStock value from backend
const outOfStock = true;
