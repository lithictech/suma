import Stack from "../ui/Stack.tsx";

export function DemoStack({ children }) {
  return (
    <Stack col gap={3} style={{ maxWidth: 700 }}>
      {children}
    </Stack>
  );
}
