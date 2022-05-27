import onboardingDiscounts from "../assets/images/onboarding-discounts.jpg";
import onboardingFood from "../assets/images/onboarding-food.jpg";
import onboardingScooters from "../assets/images/onboarding-scooters.jpg";
import TopNav from "../components/TopNav";
import React from "react";
import Carousel from "react-bootstrap/Carousel";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import { Link } from "react-router-dom";

const Onboarding = () => {
  return (
    <div className="main-container">
      <TopNav />
      <Row>
        <Col>
          <Carousel fade className="onboarding-carousel rounded overflow-hidden">
            <CarouselSlide
              src={onboardingScooters}
              title="Mobility"
              subtitle="We provide clean-energy transportation with electric scooters and bikes"
            />
            <CarouselSlide
              src={onboardingDiscounts}
              title="Save Money"
              subtitle="Big discounts on things that you buy the most"
            />
            <CarouselSlide
              src={onboardingFood}
              title="Food"
              subtitle="Hungry? Get food directly to your door"
            />
          </Carousel>
          <Link
            to="/onboarding/signup"
            className="btn btn-success w-100 p-2 my-2 mt-4 rounded-pill"
          >
            Continue
          </Link>
        </Col>
      </Row>
    </div>
  );
};

export default Onboarding;

const CarouselSlide = React.forwardRef((props, ref) => {
  const { src, title, subtitle, className } = props;
  return (
    <Carousel.Item ref={ref} className={className} interval={4500}>
      <img className="d-block w-100" src={src} alt="onboarding carousel slide" />
      <Carousel.Caption className="bg-dark bg-opacity-75 rounded">
        <h5>{title}</h5>
        <p className="px-3">{subtitle}</p>
      </Carousel.Caption>
    </Carousel.Item>
  );
});
