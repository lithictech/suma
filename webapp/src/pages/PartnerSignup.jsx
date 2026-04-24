import onboardingFood from "../assets/images/onboarding-food.jpg";
import onboardingMobility from "../assets/images/onboarding-mobility.jpg";
import onboardingUtilities from "../assets/images/onboarding-utilities.jpg";
import RLink from "../components/RLink";
import { imageAltT, t } from "../localization";
import React from "react";
import Button from "react-bootstrap/Button";
import Carousel from "react-bootstrap/Carousel";

export default function PartnerSignup() {
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
        <Button
          to="/onboarding/signup"
          as={RLink}
          variant="outline-primary"
          className="mt-4"
        >
          {t("forms.continue")}
        </Button>
      </div>
    </>
  );
}
