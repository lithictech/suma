import { base64decode, base64encode } from "../shared/base64";
import React from "react";

export default function useUrlMarshal() {
  const marshalToUrl = React.useCallback((key, model) => {
    const j = JSON.stringify(model);
    const ej = base64encode(j);
    return `${key}=${ej}`;
  }, []);
  const unmarshalFromUrl = React.useCallback((key, url) => {
    const v = new URL(url).searchParams.get(key);
    try {
      const ej = base64decode(v);
      return JSON.parse(ej);
    } catch (e) {
      return null;
    }
  }, []);
  return { marshalToUrl, unmarshalFromUrl };
}
