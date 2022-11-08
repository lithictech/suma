import api from "../api";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useLocalStorageState from "../shared/react/useLocalStorageState";
import React from "react";

export const OfferingContext = React.createContext();
export const useOffering = () => React.useContext(OfferingContext);

const NOOP = Symbol("noop");

export function OfferingProvider({ children }) {
  const [offering, setOfferingInner] = React.useState(null);
  const [cart, setCartInner] = useLocalStorageState("sumacart", { items: [] });
  const [products, setProductsInner] = React.useState([]);

  const fetchOfferingProducts = React.useCallback(
    (id) => {
      id = parseInt(id, 10);
      if (id === offering?.id) {
        return Promise.resolve(NOOP);
      }
      return api.getCommerceOfferingProducts({ id });
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
        setCartInner(resp.data.cart);
        setProductsInner(resp.data.items);
      });
    },
    [asyncFetch, setCartInner]
  );

  return (
    <OfferingContext.Provider
      value={{
        initializeToOffering,
        offering,
        products,
        cart,
        setCart: setCartInner,
        loading,
        error,
      }}
    >
      {children}
    </OfferingContext.Provider>
  );
}
