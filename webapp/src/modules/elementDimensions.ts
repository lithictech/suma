/**
 * Thanks to https://stackoverflow.com/a/23749355
 */
export default function elementDimensions(elOrSelector?: string | HTMLElement | null): {
  h: number;
  w: number;
  mx: number;
  my: number;
} {
  if (!elOrSelector) {
    return { h: 0, w: 0, mx: 0, my: 0 };
  }
  const el =
    typeof elOrSelector === "string"
      ? document.querySelector<HTMLElement>(elOrSelector)!
      : elOrSelector;
  const styles = window.getComputedStyle(el);
  const my = parseFloat(styles["marginTop"]) + parseFloat(styles["marginBottom"]);
  const mx = parseFloat(styles["marginLeft"]) + parseFloat(styles["marginRight"]);
  return {
    h: el.offsetHeight + my,
    w: el.offsetWidth + mx,
    mx,
    my,
  };
}
