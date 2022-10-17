import api from "../api";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import clsx from "clsx";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function FoodDetails() {
  const [params] = useSearchParams();
  const getFoodDetails = React.useCallback(() => {
    return api.getFoodDetails({ id: params.get("id") }).catch((e) => console.log(e));
  }, [params]);
  const {
    state: details,
    loading: detailsLoading,
    error: detailsError,
  } = useAsyncFetch(getFoodDetails, {
    default: {},
    pickData: true,
  });
  if (detailsError) {
    return console.log(
      "TODO: output message: This product does not exist anymore or may be out of stock."
    );
  }
  if (detailsLoading) {
    return <PageLoader />;
  }
  return (
    <>
      <LinearBreadcrumbs back />
      <img src={details.imageLink} alt={details.name} />
      <h3 className="mt-4 mb-2">{details.name}</h3>
      <h5>
        <Money className={clsx("me-2", details.discountedAmount && "text-success")}>
          {details.amount}
        </Money>
        {details.discountedAmount && (
          <strike>
            <Money>{details.discountedAmount}</Money>
          </strike>
        )}
      </h5>
      <b>{details.weight}</b>
      <p>By {details.partner.name}</p>
      <h5 className="mt-4 mb-2">Details</h5>
      <p>{details.description}</p>
      <h5 className="mt-4 mb-2">Ingredients</h5>
      {details.ingredients.map((i, idx) => (
        <span key={i} className="me-2">
          {i}
          {details.ingredients.length > 1 &&
            details.ingredients.length !== idx + 1 &&
            ", "}
        </span>
      ))}
    </>
  );
}
