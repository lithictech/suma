import PageLayoutUntyped from "../components/PageLayout.jsx";
import React from "react";

// PageLayout is still untyped (.jsx); its JSDoc uses flat @param tags instead of
// the dotted `props.x` form for a destructured parameter, which makes TS's
// JS-inference infer the whole props object as `string`. Cast as a stopgap.
// eslint-disable-next-line react-refresh/only-export-components
const PageLayout = PageLayoutUntyped as React.ComponentType<any>;

/**
 * Higher-order component for PageLayout.
 * See it for more options.
 */
export default function withPageLayout(options?: Record<string, any>) {
  options = options || {};
  return (Wrapped: React.ComponentType<any>) => {
    return (props: any) => {
      return (
        <PageLayout {...options}>
          <Wrapped {...props} />
        </PageLayout>
      );
    };
  };
}
