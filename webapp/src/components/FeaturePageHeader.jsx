import LayoutContainer from "./LayoutContainer";
import React from "react";

export default function FeaturePageHeader({ children, imgSrc, imgAlt }) {
  return (
    <>
      <img src={imgSrc} alt={imgAlt} className="thin-header-image" />
      <LayoutContainer top gutters>
        {children}
      </LayoutContainer>
    </>
  );
}
