export default function badContext(name: string) {
  return () => console.error(`${name} must be used within a Provider`);
}
