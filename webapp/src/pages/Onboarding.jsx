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
          imgSrc={onboardingMobility}
          imgAlt={t("mobility:person_riding_scooter")}
          title={t("onboarding:mobility_title")}
          subtitle={t("onboarding:mobility_text")}
        />
        <CarouselSlide
          imgSrc={onboardingUtilities}
          imgAlt={t("utilities:solar_panels")}
          title={t("onboarding:utilities_title")}
          subtitle={t("onboarding:utilities_text")}
        />
        <CarouselSlide
          imgSrc={onboardingFood}
          imgAlt={t("food:local_food_stand")}
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
  const { imgSrc, imgAlt, title, subtitle, ...rest } = props;
  return (
    <Carousel.Item ref={ref} interval={2200} {...rest}>
      <div className="onboarding-carousel-image-overlay" />
      <img className="onboarding-carousel-image" src={imgSrc} alt={imgAlt} />
      <Carousel.Caption>
        <h3>{title}</h3>
        <p className="px-3 lead">{subtitle}</p>
      </Carousel.Caption>
    </Carousel.Item>
  );
});
