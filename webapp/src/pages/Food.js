// import foodImage from "../assets/images/onboarding-food.jpg";
// import WaitingListPage from "../components/WaitingListPage";
// import { mdp, t } from "../localization";
import api from "../api";
import AppNav from "../components/AppNav";
import PageLoader from "../components/PageLoader";
import { t } from "../localization";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import React from "react";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import { Link } from "react-router-dom";

export default function Food() {
  const getFood = React.useCallback(() => {
    return api.getFood().catch((e) => console.log(e));
  }, []);
  const { state: food, loading: listLoading } = useAsyncFetch(getFood, {
    default: {},
    pickData: true,
  });
  console.log(food);
  if (listLoading) {
    return <PageLoader />;
  }
  return (
    <>
      <AppNav />
      <LayoutContainer gutters>
        <h3 className="my-4">{t("food:title")}</h3>
        <Row>
          {food.data.map((f) => (
            <Col xs={6} key={f.name} className="position-relative mb-4">
              <img src={f.imageLink} alt={f.name} />
              <h5>
                <Link to={`/food-details?id=${f.id}`}>{f.name}</Link>
              </h5>
              <h5>
                <Money className={clsx("me-2", f.discountedAmount && "text-success")}>
                  {f.amount}
                </Money>
                {f.discountedAmount && (
                  <strike>
                    <Money>{f.discountedAmount}</Money>
                  </strike>
                )}
              </h5>
              <b>{f.weight}</b>
              <p>By {f.partner.name}</p>
            </Col>
          ))}
        </Row>
      </LayoutContainer>
    </>
  );
}
