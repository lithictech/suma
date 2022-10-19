import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import ButtonGroup from "react-bootstrap/ButtonGroup";
import Dropdown from "react-bootstrap/Dropdown";

export default function FoodWidget({ productId, maxQuantity, quantity }) {
  const [maxQ] = React.useState(maxQuantity || 200);
  const [selectedQuantity, setSelectedQuantity] = React.useState(quantity || 0);

  const handleQuantityChange = (add) => {
    // TODO: connect cart API once the backend cart mechanism is done
    // use productId in API to change correct product
    setSelectedQuantity((previousValue) => (add ? previousValue + 1 : previousValue - 1));
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
          <Button variant="danger" onClick={() => handleQuantityChange()}>
            -
          </Button>
          <Dropdown
            variant="success"
            as={ButtonGroup}
            title={selectedQuantity}
            onSelect={(q) => setSelectedQuantity(Number(q))}
          >
            <Dropdown.Toggle variant="success">{selectedQuantity}</Dropdown.Toggle>
            <Dropdown.Menu style={{ height: "300px", overflowY: "scroll" }}>
              <DropdownQuantities />
            </Dropdown.Menu>
          </Dropdown>
        </>
      )}
      <Button
        variant="success"
        onClick={() => handleQuantityChange({ add: true })}
        className={clsx(selectedQuantity === maxQ && "disabled")}
      >
        +
      </Button>
    </ButtonGroup>
  );
}
