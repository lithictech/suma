import addIcon from "../assets/images/food-widget-add.svg";
import subtractIcon from "../assets/images/food-widget-subtract.svg";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import ButtonGroup from "react-bootstrap/ButtonGroup";
import Dropdown from "react-bootstrap/Dropdown";

export default function FoodWidget({ productId, maxQuantity, quantity, large }) {
  const [maxQ] = React.useState(maxQuantity || 1);
  const [selectedQuantity, setSelectedQuantity] = React.useState(quantity || 0);
  const btnClasses = !large ? smallBtnClasses : largeBtnClasses;

  const handleQuantityChange = (to) => {
    // TODO: connect cart API once the backend cart mechanism is done
    // use productId in API to change correct product
    setSelectedQuantity(Number(to));
  };

  const DropdownQuantities = () => {
    return [...Array(maxQ + 1)].map((_, i) => (
      <Dropdown.Item
        key={i}
        eventKey={i}
        className={clsx(i === selectedQuantity && "active")}
      >
        {i}
      </Dropdown.Item>
    ));
  };
  return (
    <ButtonGroup aria-label="add-to-cart widget" className="shadow">
      {selectedQuantity > 0 && (
        <>
          <Button
            variant="danger"
            onClick={() => handleQuantityChange(selectedQuantity - 1)}
            className={btnClasses}
          >
            <img src={subtractIcon} alt="remove from cart" width="32px" />
          </Button>
          <Dropdown
            variant="success"
            as={ButtonGroup}
            title={selectedQuantity}
            onSelect={(quantity) => handleQuantityChange(quantity)}
          >
            <Dropdown.Toggle variant="success" className="py-0 px-2">
              {selectedQuantity}
            </Dropdown.Toggle>
            <Dropdown.Menu className="food-widget-dropdown-menu" renderOnMount={true}>
              <DropdownQuantities />
            </Dropdown.Menu>
          </Dropdown>
        </>
      )}
      <Button
        variant="success"
        onClick={() => handleQuantityChange(selectedQuantity + 1)}
        className={clsx(btnClasses, selectedQuantity === maxQ && "disabled")}
      >
        <img src={addIcon} alt="add to cart" width="32px" />
        {large && selectedQuantity === 0 && (
          <span className="text-capitalize fs-5 align-middle ms-1 pe-2">Add to cart</span>
        )}
      </Button>
    </ButtonGroup>
  );
}

const smallBtnClasses = "lh-1 m-0 p-0";
const largeBtnClasses = "lh-1 m-0 p-2";
