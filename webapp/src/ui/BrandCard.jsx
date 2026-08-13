import "./BrandCard.css";
import React from "react";

export default function BrandCard({ pillText, title, text, helpText, children }) {
  return (
    <div className="brand-card">
      {pillText && <div className="brand-card-pill">{pillText}</div>}
      <h2 className="brand-card-title">{title}</h2>
      <div className="brand-card-text">{text}</div>
      {children}
      <div className="brand-card-help">{helpText}</div>
    </div>
  );
}
