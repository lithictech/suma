export default function badContext(name) {
  return () => console.error(`${name} must be used within a Provider`);
}
