import { ClientsideSearchParamsContext } from "./ClientsideSearchParamsProvider.jsx";
import React from "react";

/**
 * Work with search params on the client side (using pushState), rather than react-router.
 * This is required for things like filters, where we want to preserve state,
 * but avoid a re-render. This USED to work in react-router but it was broken in
 * v5 or v6. See https://github.com/remix-run/react-router/issues/8908
 * for a pretty comprehensive rundown.
 *
 * IMPORTANT: Because this bypasses react-router, things like useSearchParams
 * WILL NOT WORK with these local updates.
 *
 * @returns {ClientsideSearchParams}
 */
export default function useClientsideSearchParams() {
  return React.useContext(ClientsideSearchParamsContext);
}
