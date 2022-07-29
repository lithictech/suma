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
          title={t("onboarding:mobility_title")}
          subtitle={t("onboarding:mobility_text")}
        />
        <CarouselSlide
          src={onboardingUtilities}
          title={t("onboarding:utilities_title")}
          subtitle={t("onboarding:utilities_text")}
        />
        <CarouselSlide
          src={onboardingFood}
          title={t("onboarding:food_title")}
          subtitle={t("onboarding:food_text")}
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
    <Carousel.Item ref={ref} interval={2200} {...rest}>
      <div className="onboarding-carousel-image-overlay" />
      <img className="onboarding-carousel-image" src={src} alt={title} />
      <Carousel.Caption>
        <h3>{title}</h3>
        <p className="px-3 lead">{subtitle}</p>
      </Carousel.Caption>
    </Carousel.Item>
  );
});
