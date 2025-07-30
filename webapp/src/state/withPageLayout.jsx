import PageLayout from "../components/PageLayout.jsx";
import React from "react";

/**
 * Higher-order component for PageLayout.
 * See it for more options.
 */
export default function withPageLayout(options) {
  options = options || {};
  return (Wrapped) => {
    return (props) => {
      return (
        <PageLayout {...options}>
          <Wrapped {...props} />
        </PageLayout>
      );
    };
  };
}
