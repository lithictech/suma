import "./ChecklistItem.css";
import clsx from "clsx";
import React from "react";

export default function ChecklistItem({ variant, step, children }) {
  step = step || 0;
  let iconContent;
  if (variant === "checked") {
    iconContent = (
      <svg
        width="9"
        height="8"
        viewBox="0 0 9 8"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M0.597656 4.03345L3.34766 6.78345L7.47266 0.595947"
          stroke="#4D6B44"
          strokeWidth="1.19167"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    );
  } else if (variant === "current") {
    iconContent = "" + step;
  } else {
    variant = "future";
    iconContent = "" + step;
  }
  return (
    <div className="checklist-item">
      <div className={`checklist-item-icon checklist-item-icon-${variant}`}>
        {iconContent}
      </div>
      {children}
    </div>
  );
}

const iconSize = 16;

//
//
// </svg>
