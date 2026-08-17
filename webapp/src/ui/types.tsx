export type Direction = "horizontal" | "vertical";

export interface DirectionProps {
  direction?: Direction;
  vertical?: boolean;
  col?: boolean;
  column?: boolean;
  horizontal?: boolean;
  row?: boolean;
}

export function getDirection(props: DirectionProps): Direction {
  if (props.vertical || props.col || props.column) {
    return "vertical";
  }
  if (props.horizontal || props.row) {
    return "horizontal";
  }
  return props.direction || "horizontal";
}
