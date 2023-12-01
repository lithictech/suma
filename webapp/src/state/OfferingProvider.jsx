import api from "../api";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import React from "react";

export const OfferingContext = React.createContext({});

const NOOP = Symbol("noop");

export default function OfferingProvider({ children }) {
  const [offering, setOfferingInner] = React.useState({});
  const [vendors, setVendorsInner] = React.useState([]);
  // Do not store things in local storage here:
  // because carts depend on everything else being loaded,
  // saving just the cart causes errors.
  const [cart, setCartInner] = React.useState({ items: [] });
  const [products, setProductsInner] = React.useState([]);

  const reset = React.useCallback(() => {
    setOfferingInner({});
    setVendorsInner([]);
    // Do not store things in local storage here:
    // because carts depend on everything else being loaded,
    // saving just the cart causes errors.
    setCartInner({ items: [] });
    setProductsInner([]);
  }, []);

  const fetchOfferingProducts = React.useCallback(
    (id) => {
      id = parseInt(id, 10);
      if (id === offering?.id) {
        return Promise.resolve(NOOP);
      }
      return api.getCommerceOfferingDetails({ id });
    },
    [offering?.id]
  );

  const { asyncFetch, loading, error } = useAsyncFetch(fetchOfferingProducts, {
    default: {},
    doNotFetchOnInit: true,
  });

  const initializeToOffering = React.useCallback(
    (offeringId) => {
      asyncFetch(offeringId).then((resp) => {
        if (resp === NOOP) {
          return;
        }
        setOfferingInner(resp.data.offering);
        setVendorsInner(resp.data.vendors);
        setCartInner(resp.data.cart);
        setProductsInner(resp.data.items);
      });
    },
    [asyncFetch, setCartInner]
  );

  const value = React.useMemo(
    () => ({
      initializeToOffering,
      offering,
      vendors,
      products,
      cart,
      setCart: setCartInner,
      loading,
      error,
      reset,
    }),
    [cart, error, initializeToOffering, loading, offering, products, reset, vendors]
  );

  return <OfferingContext.Provider value={value}>{children}</OfferingContext.Provider>;
}
