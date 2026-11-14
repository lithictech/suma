import { ThemeSpacing } from "../types/theme";
import Stack from "../ui/Stack.tsx";
import React from "react";

export function DemoStack({
  row,
  gap = 4,
  wrap = false,
  className,
  children,
}: {
  row?: boolean;
  gap?: ThemeSpacing;
  wrap?: boolean;
  className?: string;
  children: React.ReactNode;
}) {
  const direction = row ? "horizontal" : "vertical";
  return (
    <Stack
      direction={direction}
      gap={gap}
      style={{ maxWidth: wrap ? undefined : 700 }}
      wrap={wrap}
      className={className}
    >
      {children}
    </Stack>
  );
}
