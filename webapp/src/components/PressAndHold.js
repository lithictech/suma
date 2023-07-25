import useLongPress from "../shared/react/useLongPress";
// Cannot use CSS modules due to animation
import "./PressAndHold.css";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";

// If changing these, you MUST review the CSS.
const HOLD_SECS = 2;
const SIZE_RATIO = 0.7;

export default function PressAndHold({ size, onHeld, children }) {
  size = size || 160;
  const innerSize = size * SIZE_RATIO;

  async function handleHeld() {
    buttonRef.current.disabled = true;
    try {
      await onHeld();
    } finally {
      buttonRef.current.disabled = false;
    }
  }

  const isPressed = useLongPress(() => {
    handleHeld().then(null);
  }, HOLD_SECS * 1000);

  const buttonRef = React.useRef(null);

  return (
    <div
      className="position-relative d-flex align-items-center justify-content-center mt-0"
      style={{ height: size + 8 }}
    >
      <div className="position-absolute d-block" style={{ width: size, height: size }}>
        <div
          className={clsx(
            "press-and-hold-feedback",
            isPressed.isOn && "press-and-hold-feedback-active"
          )}
          style={{ width: size, height: size }}
        />
      </div>
      <Button
        variant="primary"
        ref={buttonRef}
        className="position-absolute press-and-hold-button"
        style={{ width: innerSize, height: innerSize }}
        onMouseDown={isPressed.turnOn}
        onMouseUp={isPressed.turnOff}
        onMouseLeave={isPressed.turnOff}
        onTouchStart={isPressed.turnOn}
        onTouchEnd={isPressed.turnOff}
      >
        {children}
      </Button>
    </div>
  );
}
