import api from "../api";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import clsx from "clsx";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function FoodDetails() {
  const [params] = useSearchParams();
  const getFoodProductDetails = React.useCallback(() => {
    return api.getFoodProductDetails({ id: params.get("id") });
  }, [params]);
  const { state: productDetails, loading: productDetailsLoading } = useAsyncFetch(
    getFoodProductDetails,
    {
      default: {},
      pickData: true,
    }
  );
  // TODO: Recieve this cart from backend API once cart mechanism is done
  const cart = [{ key: 1, productId: 3, maxQuantity: 200, quantity: 2 }];
  if (productDetailsLoading) {
    return <PageLoader />;
  }
  return (
    <>
      <LinearBreadcrumbs back />
      {/* TODO: refactor image src with correct link */}
      <div className="position-relative">
        <img
          src="/temporary-food-chicken.jpg"
          alt={productDetails.name}
          className="w-100"
        />
        <div className="food-widget-container position-absolute">
          {cart.map((product) =>
            product.productId === productDetails.id ? (
              <FoodWidget key={productDetails.id} {...product} />
            ) : (
              <FoodWidget key={productDetails.id} {...productDetails} />
            )
          )}
        </div>
      </div>
      <h3 className="mt-4 mb-2">{productDetails.name}</h3>
      <h5>
        <Money className={clsx("me-2", productDetails.discountedPrice && "text-success")}>
          {productDetails.discountedPrice || productDetails.price}
        </Money>
        {productDetails.discountedPrice && (
          <strike>
            <Money>{productDetails.price}</Money>
          </strike>
        )}
      </h5>
      <b>{productDetails.weight}</b>
      <p>By {productDetails.partner.name}</p>
      <hr />
      <h5 className="mt-4 mb-2">Details</h5>
      <p>{productDetails.description}</p>
      <h5 className="mt-4 mb-2">Ingredients</h5>
      {productDetails.ingredients.map((i, idx) => (
        <span key={i} className="me-2">
          {i}
          {productDetails.ingredients.length > 1 &&
            productDetails.ingredients.length !== idx + 1 &&
            ", "}
        </span>
      ))}
    </>
  );
}
