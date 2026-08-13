/**
 * Remove this with React 18.
 */
export default function useId() {
  lastId++;
  return `id-${lastId}`;
}

let lastId = 0;
