import api from "../api";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import React from "react";
import Stack from "react-bootstrap/Stack";
import { useParams } from "react-router-dom";

export default function FoodDetails() {
  const { productId } = useParams();
  const getFoodOfferingDetails = React.useCallback(() => {
    return api.getFoodOfferingDetails({ productId: productId });
  }, [productId]);
  const { state: offeringDetails, loading: offeringDetailsLoading } = useAsyncFetch(
    getFoodOfferingDetails,
    {
      default: {},
      pickData: true,
    }
  );
  if (offeringDetailsLoading) {
    return <PageLoader />;
  }
  return (
    <>
      <LayoutContainer className="pt-2">
        <LinearBreadcrumbs back />
      </LayoutContainer>
      {/* TODO: refactor image src with correct link */}
      <img
        src="/temporary-food-chicken.jpg"
        alt={offeringDetails.name}
        className="w-100"
      />
      <LayoutContainer top>
        <h3 className="mb-2">{offeringDetails.name}</h3>
        <Stack direction="horizontal">
          <h5>
            <Money
              className={clsx("me-2", offeringDetails.discountedPrice && "text-success")}
            >
              {offeringDetails.discountedPrice || offeringDetails.price}
            </Money>
            {offeringDetails.discountedPrice && (
              <strike>
                <Money>{offeringDetails.price}</Money>
              </strike>
            )}
          </h5>
          <div className="ms-auto">
            <FoodWidget {...offeringDetails} large={true} />
          </div>
        </Stack>
        <b>{offeringDetails.weight}</b>
        <p>By {offeringDetails.partner.name}</p>
        <hr />
        <h5 className="mt-4 mb-2">Details</h5>
        <p>{offeringDetails.description}</p>
        <h5 className="mt-4 mb-2">Ingredients</h5>
        {offeringDetails.ingredients.map((i, idx) => (
          <span key={i}>
            {i}
            {offeringDetails.ingredients.length > 1 &&
              offeringDetails.ingredients.length !== idx + 1 &&
              ", "}
          </span>
        ))}
      </LayoutContainer>
    </>
  );
}
