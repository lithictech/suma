import onboardingFood from "../assets/images/onboarding-food.jpg";
import onboardingMobility from "../assets/images/onboarding-mobility.jpg";
import onboardingUtilities from "../assets/images/onboarding-utilities.jpg";
import RLink from "../components/RLink";
import { t } from "../localization";
import React from "react";
import Button from "react-bootstrap/Button";
import Carousel from "react-bootstrap/Carousel";

const Onboarding = () => {
  return (
    <>
      <Carousel fade className="onboarding-carousel overflow-hidden">
        <CarouselSlide
          src={onboardingMobility}
          title="Mobility"
          subtitle="We provide clean-energy transportation with electric scooters and bikes"
        />
        <CarouselSlide
          src={onboardingUtilities}
          title="Save Money"
          subtitle="Big discounts on things that you buy the most"
        />
        <CarouselSlide
          src={onboardingFood}
          title="Food"
          subtitle="Hungry? Get food directly to your door"
        />
      </Carousel>
      <div className="button-stack">
        <Button
          to="/onboarding/signup"
          as={RLink}
          variant="outline-primary"
          className="mt-4"
        >
          {t("forms:continue")}
        </Button>
      </div>
    </>
  );
};

export default Onboarding;

const CarouselSlide = React.forwardRef((props, ref) => {
  const { src, title, subtitle, ...rest } = props;
  return (
    <Carousel.Item ref={ref} interval={1500} {...rest}>
      <div className="onboarding-carousel-image-overlay" />
      <img className="onboarding-carousel-image" src={src} alt="" />
      <Carousel.Caption>
        <h3>{title}</h3>
        <p className="px-3 lead">{subtitle}</p>
      </Carousel.Caption>
    </Carousel.Item>
  );
});
