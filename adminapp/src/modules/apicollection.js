import isNil from "lodash/isNil";

/**
 * Raise unless the collection has items,
 * and all have been returned from the API (hasMore).
 * Check this before collection editing.
 * @param collection
 */
export function assertFullCollection(collection) {
  if (!collection.items) {
    throw new Error("need to pass an API collection");
  }
  if (collection.currentPage !== 1) {
    throw new Error("collection must be loaded from page 1");
  }
  if (collection.hasMore) {
    throw new Error("collection must be loaded with all:true in the entity");
  }
}

export function isCollection(v) {
  return typeof v === "object" && !isNil(v) && Array.isArray(v.items);
}
/**
 * Call set with a collection object with the given items.
 * currentPage and hasMore are set so assertFullCollection passes.
 * @param {function} set
 * @param {Array} items
 */
export function setCollectionItems(set, items) {
  set(itemsToCollection(items));
}

export function itemsToCollection(items) {
  return { items, currentPage: 1, hasMore: false };
}

/**
 * Given a POST body, convert any collection hashes into just
 * an array of their items.
 * @param {object} h
 */
export function simplifyCollections(h) {
  const r = {};
  Object.entries(h).forEach(([k, v]) => {
    if (isCollection(v)) {
      r[k] = v.items;
    } else {
      r[k] = v;
    }
  });
  return r;
}
