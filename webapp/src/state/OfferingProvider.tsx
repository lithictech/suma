import api from "../api";
import useAsyncFetch from "./useAsyncFetch";
import React from "react";

interface OfferingActions {
  initializeToOffering: (offeringId: number) => void;
  setOfferingFromResponse: (data: OfferingWithContext) => void;
  reset: () => void;
}

interface OfferingData {
  offering: Offering;
  vendors: Vendor[];
  products: PricedOfferingProduct[];
  listableProducts: PricedOfferingProduct[];
  cart: Cart;
}

type OfferingContextValue =
  | ({ loading: true; error?: undefined } & Partial<OfferingData> &
      Partial<OfferingActions>)
  | ({ loading: false; error: any } & Partial<OfferingData> & Partial<OfferingActions>)
  | ({ loading: false; error?: undefined } & OfferingData & OfferingActions);

export const OfferingContext = React.createContext<OfferingContextValue>({
  loading: true,
});

export default function OfferingProvider({ children }: { children: React.ReactNode }) {
  const [offering, setOfferingInner] = React.useState<Offering | null>();
  const [vendors, setVendorsInner] = React.useState<Vendor[]>([]);
  // Do not store things in local storage here:
  // because carts depend on everything else being loaded,
  // saving just the cart causes errors.
  const [cart, setCartInner] = React.useState<Cart | null>(null);
  const [products, setProductsInner] = React.useState<PricedOfferingProduct[]>([]);

  const reset = React.useCallback(() => {
    setOfferingInner(null);
    setVendorsInner([]);
    // Do not store things in local storage here:
    // because carts depend on everything else being loaded,
    // saving just the cart causes errors.
    setCartInner(null);
    setProductsInner([]);
  }, []);

  const fetchOfferingDetails = React.useCallback(
    (data?: Record<string, any>) => api.getCommerceOfferingDetails({ id: data!.id }),
    []
  );

  const { asyncFetch, loading, error } = useAsyncFetch(fetchOfferingDetails, {
    doNotFetchOnInit: true,
  });

  const setOfferingFromResponse = React.useCallback((data: OfferingWithContext) => {
    setOfferingInner(data.offering);
    setVendorsInner(data.vendors);
    setCartInner(data.cart);
    setProductsInner(data.items);
  }, []);

  const initializeToOffering = React.useCallback(
    (id: number) => {
      asyncFetch({ id }).then((resp) => {
        setOfferingFromResponse(resp.data as OfferingWithContext);
      });
    },
    [asyncFetch, setOfferingFromResponse]
  );

  const listableProducts = products.filter((p) => p.listable);

  const value = React.useMemo<OfferingContextValue>(() => {
    if (loading) {
      return { loading: true };
    } else if (error) {
      return { error, loading: false };
    }
    return {
      initializeToOffering,
      offering,
      setOfferingFromResponse,
      vendors,
      products,
      listableProducts,
      cart,
      reset,
      loading: false,
      error: undefined,
    } as OfferingContextValue;
  }, [
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
  ]);

  return <OfferingContext.Provider value={value}>{children}</OfferingContext.Provider>;
}
