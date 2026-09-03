import Stack from "../ui/Stack.tsx";
import React from "react";

export function DemoStack({
  row,
  gap = 3,
  wrap = false,
  children,
}: {
  row?: boolean;
  gap?: number;
  wrap?: boolean;
  children: React.ReactNode;
}) {
  const direction = row ? "horizontal" : "vertical";
  return (
    <Stack
      direction={direction}
      gap={gap}
      style={{ maxWidth: wrap ? undefined : 700 }}
      wrap={wrap}
    >
      {children}
    </Stack>
  );
}
