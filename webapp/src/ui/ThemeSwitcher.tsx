import { ButtonProps } from "./Button.tsx";
import Stack from "./Stack.tsx";
import React from "react";

export default function ThemeSwitcher({ children, variant, type, ...rest }: ButtonProps) {
  return (
    <Stack col gap={4}>
      <h4>Appearance</h4>
      <h4>Contrast</h4>
    </Stack>
  );
}
