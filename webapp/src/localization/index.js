import i18n from "i18next";
import React from "react";
import ReactMarkdown from "react-markdown";

export function md(key, options = {}) {
  if (process.env.NODE_ENV === "development") {
    if (!key.endsWith("_md")) {
      console.error(
        `loc key '${key}' does not end with _md but md() was used (is unnecessarily slow)`
      );
    }
  }
  return (
    <ReactMarkdown
      components={{
        // avoids element descending issues e.g. p cannot be descendent of p
        p: React.Fragment,
      }}
    >
      {i18n.t(key, options)}
    </ReactMarkdown>
  );
}

export function t(key, options = {}) {
  if (process.env.NODE_ENV === "development") {
    if (key.endsWith("_md")) {
      console.error(
        `loc key '${key}' ends with _md but t() was used (will not render markdown)`
      );
    }
  }
  return i18n.t(key, options);
}
