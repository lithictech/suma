import sumaLogo from "../assets/images/suma-logo-word-512.png";
import { imageAltT } from "../localization";
import Link from "../routing/Link.tsx";
import Stack from "../ui/Stack.tsx";
import TranslationToggle from "./TranslationToggle.tsx";
import React from "react";

export default function ContentPageHeader({ title }: { title: React.ReactNode }) {
  return (
    <Stack row gap={3} center className="bgcolor-tint-primary px-3 py-2">
      <Link to="/">
        <img src={sumaLogo} height={64} alt={imageAltT("suma_logo")} />
      </Link>
      <Stack col gap={1}>
        <h1>{title}</h1>
        <TranslationToggle clearHash variant="short" />
      </Stack>
    </Stack>
  );
}
