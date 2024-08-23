import api from "../api";
import { useUser } from "./user";
import camelCase from "lodash/camelCase";
import React from "react";

export default function useRoleAccess() {
  const { user } = useUser();
  const [resourceAccess, setResourceAccess] = React.useState(null);

  React.useEffect(() => {
    api.getResourceAccessMeta().then((r) => {
      setResourceAccess(r.data);
    });
  }, []);

  const can = React.useCallback(
    (key, rw) => {
      if (!user) {
        return false;
      }
      key = camelCase(key);
      const cando = user.roleAccess[key];
      if (!cando) {
        return false;
      }
      return cando.includes(rw);
    },
    [user]
  );

  const canResource = React.useCallback(
    (resource, rw) => {
      if (!resourceAccess) {
        return false;
      }
      if (!resource) {
        console.error("You must pass the 'resource' prop to check access.");
        return false;
      }
      resource = camelCase(resource);
      const got = resourceAccess[resource];
      if (!got) {
        console.error(
          `resource prop '${resource}' is invalid, must be one of:`,
          Object.keys(resourceAccess)
        );
        return false;
      }
      const idx = rw === "read" ? 0 : 1;
      const key = got[idx];
      return can(key, rw);
    },
    [can, resourceAccess]
  );
  const canRead = React.useCallback((key) => can(key, "read"), [can]);
  const canWrite = React.useCallback((key) => can(key, "write"), [can]);
  const canReadResource = React.useCallback(
    (key) => canResource(key, "read"),
    [canResource]
  );
  const canWriteResource = React.useCallback(
    (key) => canResource(key, "write"),
    [canResource]
  );

  const result = React.useMemo(
    () => ({ canRead, canWrite, canReadResource, canWriteResource }),
    [canRead, canWrite, canReadResource, canWriteResource]
  );
  return result;
}
