import identity from "lodash/identity";
import React from "react";

const makeCache = (store: Storage) => {
  return {
    /**
     * Return parsed JSON from local storage,
     * stored under the given key.
     * Return defaultValue on failure (not present, parse failure, etc).
     *
     * NOTE: The parsed value may be missing fields you expect,
     * either due to versioning issues, or browser stuff.
     * So always check or assign default values of complex objects.
     */
    getItem: <T = any>(field: string, defaultValue: T = {} as T): T => {
      return getItem(store, field, defaultValue);
    },
    setItem: (field: string, item: any) => {
      setItem(store, field, item);
    },
    removeItem: (field: string) => {
      try {
        store.removeItem(field);
      } catch (err) {
        console.log("Remove cache error:", err);
      }
    },
    clear: () => {
      try {
        store.clear();
      } catch (err) {
        console.log("Clear cache error:", err);
      }
    },
    useState: <T = any>(
      field: string,
      initialValue: T,
      convert?: (v: any) => T
    ): [T, (v: T) => void] => {
      convert = convert || identity;
      const [val, setVal] = React.useState<T>(
        convert(getItem(store, field, initialValue))
      );
      const setValAndCache = (v: T) => {
        setItem(store, field, v);
        return setVal(v);
      };
      return [val, setValAndCache];
    },
  };
};

export const localStorageCache = makeCache(window.localStorage);
export const sessionStorageCache = makeCache(window.sessionStorage);

function getItem<T>(store: Storage, field: string, defaultValue: T): T {
  try {
    const cachedJSON = store.getItem(field);
    if (!cachedJSON) {
      return defaultValue;
    }
    return JSON.parse(cachedJSON);
  } catch (err) {
    console.log("Get cache error: ", err);
    return defaultValue;
  }
}

function setItem(store: Storage, field: string, item: any) {
  try {
    const itemJSON = JSON.stringify(item);
    store.setItem(field, itemJSON);
  } catch (err) {
    console.log("Set cache error: ", err);
  }
}
