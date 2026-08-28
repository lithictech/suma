import Stack from "../ui/Stack.tsx";
import React from "react";

export function DemoStack({
  row,
  gap = 3,
  children,
}: {
  row?: boolean;
  gap?: number;
  children: React.ReactNode;
}) {
  const direction = row ? "horizontal" : "vertical";
  return (
    <Stack direction={direction} gap={gap} style={{ maxWidth: 700 }}>
      {children}
    </Stack>
  );
}
