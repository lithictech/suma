import Stack from "./Stack.tsx";
import React from "react";

interface FormProps extends React.HTMLAttributes<HTMLFormElement> {
  gap?: number;
  children?: React.ReactNode;
}

export default function Form({ gap = 2, children, ...rest }: FormProps) {
  return (
    <form {...rest}>
      <Stack col gap={gap}>
        {children}
      </Stack>
    </form>
  );
}
