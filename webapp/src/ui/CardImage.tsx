import "./CardImage.css";
import React from "react";

interface CardImageProps {
  children?: React.ReactNode;
}
export default function CardImage({ children }: CardImageProps) {
  return <div className="card-image">{children}</div>;
}
