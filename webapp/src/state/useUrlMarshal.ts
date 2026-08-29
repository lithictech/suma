import { base64decode, base64encode } from "../modules/base64";
import React from "react";

export default function useUrlMarshal() {
  const marshalToUrl = React.useCallback((model: any) => {
    const j = JSON.stringify(model);
    const ej = base64encode(j);
    return ej;
  }, []);
  const unmarshalFromUrl = React.useCallback((v: string | null | undefined) => {
    if (!v) {
      return null;
    }
    try {
      const ej = base64decode(v);
      return JSON.parse(ej);
    } catch {
      return null;
    }
  }, []);
  return { marshalToUrl, unmarshalFromUrl };
}
