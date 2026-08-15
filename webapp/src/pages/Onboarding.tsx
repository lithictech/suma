import onboardingFood from "../assets/images/onboarding-food.jpg";
import onboardingMobility from "../assets/images/onboarding-mobility.jpg";
import onboardingUtilities from "../assets/images/onboarding-utilities.jpg";
import { imageAltT, t } from "../localization";
import Button from "../ui/Button";
import Carousel from "../ui/Carousel";
import CarouselCaption from "../ui/CarouselCaption";
import CarouselItem from "../ui/CarouselItem";
import React from "react";

const Onboarding = () => {
  return (
    <>
      <Carousel fade className="onboarding-carousel overflow-hidden">
        <CarouselSlide
          imgSrc={onboardingMobility}
          imgAlt={imageAltT("person_riding_scooter")}
          title={t("onboarding.mobility_title")}
          subtitle={t("onboarding.mobility_text")}
        />
        <CarouselSlide
          imgSrc={onboardingUtilities}
          imgAlt={imageAltT("solar_panels")}
          title={t("onboarding.utilities_title")}
          subtitle={t("onboarding.utilities_text")}
        />
        <CarouselSlide
          imgSrc={onboardingFood}
          imgAlt={imageAltT("local_food_stand")}
          title={t("onboarding.food_title")}
          subtitle={t("onboarding.food_text")}
        />
      </Carousel>
      <div className="button-stack">
        <Button to="/onboarding/signup" variant="outline" className="mt-4">
          {t("forms.continue")}
        </Button>
      </div>
    </>
  );
};

export default Onboarding;

interface CarouselSlideProps {
  imgSrc: string;
  imgAlt: string;
  title: React.ReactNode;
  subtitle: React.ReactNode;
  [rest: string]: any;
}

const CarouselSlide = React.forwardRef<HTMLDivElement, CarouselSlideProps>(
  (props, ref) => {
    const { imgSrc, imgAlt, title, subtitle, ...rest } = props;
    return (
      <CarouselItem ref={ref} interval={2200} {...rest}>
        <div className="onboarding-carousel-image-overlay" />
        <img className="onboarding-carousel-image" src={imgSrc} alt={imgAlt} />
        <CarouselCaption>
          <h3>{title}</h3>
          <p className="px-3 lead">{subtitle}</p>
        </CarouselCaption>
      </CarouselItem>
    );
  }
);
