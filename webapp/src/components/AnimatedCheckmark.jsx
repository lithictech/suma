import clsx from "clsx";
import React from "react";

const REDUCED_MOTION_QUERY = "(prefers-reduced-motion: reduce)";

// The final frame of the animations in animated-checkmark.scss,
// shown right away to users who prefer reduced motion (WCAG 2.3.3).
const FINAL_SVG_STYLE = {
  animation: "none",
  boxShadow: "inset 0 0 0 30px var(--bs-success)",
};
const FINAL_STROKE_STYLE = { animation: "none", strokeDashoffset: 0 };

export default function AnimatedCheckmark({ className }) {
  const reduceMotion = usePrefersReducedMotion();
  return (
    <svg
      className={clsx("checkmark", className)}
      style={reduceMotion ? FINAL_SVG_STYLE : undefined}
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 52 52"
      aria-hidden="true"
      focusable="false"
    >
      <circle
        className="checkmark__circle"
        style={reduceMotion ? FINAL_STROKE_STYLE : undefined}
        cx="26"
        cy="26"
        r="25"
        fill="none"
      />
      <path
        className="checkmark__check"
        style={reduceMotion ? FINAL_STROKE_STYLE : undefined}
        fill="none"
        d="M14.1 27.2l7.1 7.2 16.7-16.8"
      />
    </svg>
  );
}

function usePrefersReducedMotion() {
  const [reduceMotion, setReduceMotion] = React.useState(() =>
    Boolean(window.matchMedia?.(REDUCED_MOTION_QUERY).matches)
  );
  React.useEffect(() => {
    const query = window.matchMedia?.(REDUCED_MOTION_QUERY);
    if (!query?.addEventListener) {
      return;
    }
    const handleChange = (e) => setReduceMotion(e.matches);
    query.addEventListener("change", handleChange);
    return () => query.removeEventListener("change", handleChange);
  }, []);
  return reduceMotion;
}
