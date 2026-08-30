import IndeterminateLoader from "../ui/IndeterminateLoader.tsx";

/**
 * Render the screen loader overlay.
 * For async work, use the `useScreenLoader` hook.
 * This is used when there is some async dependency
 * a screen has, and you want to render an overlay loader
 * while the page loads (ie, `return <ScreenLoader show />`).
 */
export default function ScreenLoader({ show }: { show: boolean }) {
  return <IndeterminateLoader variant="screen" className={show ? "" : "d-none"} />;
}
