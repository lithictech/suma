export default function accumulate(seed, collection, iteree) {
  return collection.reduce((...args) => {
    iteree(...args);
    return seed;
  }, seed);
}
