import SumaImage from "./SumaImage";
import React from "react";

export default function detailPageImageProperties(image, { h, label } = {}) {
  return [
    {
      label: label || "Image",
      value: (
        <SumaImage
          image={image}
          className="w-100"
          params={{ crop: "none" }}
          h={h || 150}
        />
      ),
    },
    {
      label: "Caption (En)",
      value: image.caption.en,
    },
    { label: "Caption (Es)", value: image.caption.es },
  ];
}
