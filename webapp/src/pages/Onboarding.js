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
          <h2>Onboarding</h2>
          <Carousel fade className="onboarding-carousel rounded overflow-hidden">
            <Carousel.Item interval={4500}>
              <img
                className="d-block w-100"
                src={onboardingScooters}
                alt="scooters slide"
              />
              <Carousel.Caption className="bg-dark bg-opacity-75 rounded">
                <h5>Mobility</h5>
                <p className="px-3">
                  We provide clean-energy transportation with electric scooters and bikes
                </p>
              </Carousel.Caption>
            </Carousel.Item>
            <Carousel.Item interval={4500}>
              <img
                className="d-block w-100"
                src={onboardingDiscounts}
                alt="discounts slide"
              />
              <Carousel.Caption className="bg-dark bg-opacity-75 rounded">
                <h5>Save Money</h5>
                <p className="px-3">Big discounts on things that you buy the most</p>
              </Carousel.Caption>
            </Carousel.Item>
            <Carousel.Item interval={4500}>
              <img className="d-block w-100" src={onboardingFood} alt="food slide" />
              <Carousel.Caption className="bg-dark bg-opacity-75 rounded">
                <h5>Food</h5>
                <p className="px-3">Hungry? Get food directly to your door</p>
              </Carousel.Caption>
            </Carousel.Item>
          </Carousel>
          <Link
            to="/onboarding/signup"
            className="btn btn-success w-100 p-2 my-2 mt-4 rounded-pill"
          >
            Continue Signup
          </Link>
        </Col>
      </Row>
    </div>
  );
};

export default Onboarding;
