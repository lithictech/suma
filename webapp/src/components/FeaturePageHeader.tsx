import LayoutContainer from "./LayoutContainer";
import React from "react";

interface FeaturePageHeaderProps {
  children?: React.ReactNode;
  imgSrc?: string;
  imgAlt?: string;
}

export default function FeaturePageHeader({
  children,
  imgSrc,
  imgAlt,
}: FeaturePageHeaderProps) {
  return (
    <>
      <img src={imgSrc} alt={imgAlt} className="thin-header-image" />
      <LayoutContainer top gutters>
        {children}
      </LayoutContainer>
    </>
  );
}
