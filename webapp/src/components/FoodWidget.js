import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import ButtonGroup from "react-bootstrap/ButtonGroup";
import Dropdown from "react-bootstrap/Dropdown";

export default function FoodWidget({ productId, maxQuantity, quantity }) {
  const [maxQ] = React.useState(maxQuantity || 200);
  const [selectedQuantity, setSelectedQuantity] = React.useState(quantity || 0);

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
          >
            -
          </Button>
          <Dropdown
            variant="success"
            as={ButtonGroup}
            title={selectedQuantity}
            onSelect={(quantity) => handleQuantityChange(quantity)}
          >
            <Dropdown.Toggle variant="success">{selectedQuantity}</Dropdown.Toggle>
            <Dropdown.Menu className="food-widget-dropdown-menu" renderOnMount={true}>
              <DropdownQuantities />
            </Dropdown.Menu>
          </Dropdown>
        </>
      )}
      <Button
        variant="success"
        onClick={() => handleQuantityChange(selectedQuantity + 1)}
        className={clsx(selectedQuantity === maxQ && "disabled")}
      >
        +
      </Button>
    </ButtonGroup>
  );
}
