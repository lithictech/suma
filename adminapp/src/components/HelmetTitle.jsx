import React from "react";
import { Helmet } from "react-helmet-async";

export default function HelmetTitle({ title }) {
  return (
    <Helmet>
      <title>{title} | Suma Admin</title>
    </Helmet>
  );
}
