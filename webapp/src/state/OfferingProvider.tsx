import api from "../api";
import useAsyncFetch from "./useAsyncFetch";
import React from "react";

interface OfferingContextValue {
  initializeToOffering: (offeringId: any) => void;
  offering: Offering;
  setOfferingFromResponse: (data: any) => void;
  vendors: Vendor[];
  products: PricedOfferingProduct[];
  listableProducts: PricedOfferingProduct[];
  cart: Cart;
  loading: boolean;
  error: any;
  reset: () => void;
}

export const OfferingContext = React.createContext<OfferingContextValue>(
  {} as OfferingContextValue
);

const NOOP = Symbol("noop");

export default function OfferingProvider({ children }: { children: React.ReactNode }) {
  const [offering, setOfferingInner] = React.useState<Offering>({} as Offering);
  const [vendors, setVendorsInner] = React.useState<Vendor[]>([]);
  // Do not store things in local storage here:
  // because carts depend on everything else being loaded,
  // saving just the cart causes errors.
  const [cart, setCartInner] = React.useState<Cart>({ items: [] } as unknown as Cart);
  const [products, setProductsInner] = React.useState<PricedOfferingProduct[]>([]);

  const reset = React.useCallback(() => {
    setOfferingInner({} as Offering);
    setVendorsInner([]);
    // Do not store things in local storage here:
    // because carts depend on everything else being loaded,
    // saving just the cart causes errors.
    setCartInner({ items: [] } as unknown as Cart);
    setProductsInner([]);
  }, []);

  const fetchOfferingProducts = React.useCallback(
    (id: any) => {
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

  const setOfferingFromResponse = React.useCallback((data: any) => {
    setOfferingInner(data.offering);
    setVendorsInner(data.vendors);
    setCartInner(data.cart);
    setProductsInner(data.items);
  }, []);

  const initializeToOffering = React.useCallback(
    (offeringId: any) => {
      asyncFetch(offeringId).then((resp: any) => {
        if (resp === NOOP) {
          return;
        }
        setOfferingFromResponse(resp.data);
      });
    },
    [asyncFetch, setOfferingFromResponse]
  );

  const listableProducts = products.filter((p) => p.listable);

  const value = React.useMemo(
    () => ({
      initializeToOffering,
      offering,
      setOfferingFromResponse,
      vendors,
      products,
      listableProducts,
      cart,
      loading,
      error,
      reset,
    }),
    [
      cart,
      error,
      initializeToOffering,
      loading,
      offering,
      setOfferingFromResponse,
      products,
      listableProducts,
      reset,
      vendors,
    ]
  );

  return <OfferingContext.Provider value={value}>{children}</OfferingContext.Provider>;
}
