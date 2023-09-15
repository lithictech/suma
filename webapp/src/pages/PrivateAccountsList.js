import api from "../api";
import loaderRing from "../assets/images/loader-ring.svg";
import Copyable from "../components/Copyable";
import ErrorScreen from "../components/ErrorScreen";
import FormError from "../components/FormError";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { mdp, t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import { useError } from "../state/useError";
import { LayoutContainer } from "../state/withLayout";
import { CanceledError } from "axios";
import forEach from "lodash/forEach";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Alert, Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";

export default function PrivateAccountsList() {
  const {
    state: accounts,
    loading: accountsLoading,
    error: accountsError,
  } = useAsyncFetch(api.getPrivateAccounts, {
    default: {},
    pickData: true,
  });

  if (accountsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (accountsLoading) {
    return <PageLoader />;
  }

  return (
    <>
      <LayoutContainer top>
        <LinearBreadcrumbs back="/dashboard" />
        <h2>{t("titles:private_accounts")}</h2>
        <p className="text-secondary mt-3">{t("private_accounts:intro")}</p>
      </LayoutContainer>
      <hr />
      {!isEmpty(accounts.items) && (
        <LayoutContainer>
          <Stack gap={3}>
            {accounts.items.map((a) => (
              <Card key={a.id} className="px-2 pb-3">
                <Card.Body>
                  <PrivateAccount account={a} />
                </Card.Body>
              </Card>
            ))}
          </Stack>
        </LayoutContainer>
      )}
      {isEmpty(accounts.items) && (
        <LayoutContainer>{mdp("private_accounts:no_private_accounts")}</LayoutContainer>
      )}
    </>
  );
}

function PrivateAccount({ account }) {
  const { address, vendorImage } = account;
  const pollingToggle = useToggle();
  const [error, setError] = useError(null);

  const pollingCallback = React.useCallback(() => {
    // Abort any ongoing request when we unmount.
    const controller = new AbortController();
    function pollAndReplace() {
      return (
        api
          // Poll with a timeout, in case the server stops responding we want to try again.
          .pollForNewPrivateAccountMagicLink(
            { id: account.id },
            { timeout: 30000, signal: controller.signal }
          )
          .then((r) => {
            if (r.data.foundChange) {
              // Turn this off before navigating in case promise callbacks don't run.
              pollingToggle.turnOff();
              window.location.href = r.data.vendorAccount.magicLink;
            } else {
              pollAndReplace();
            }
          })
          .catch((r) => {
            // If the request was aborted (due to unmount), don't restart it.
            // Otherwise, do restart it, since it is some unexpected type of error.
            if (r instanceof CanceledError) {
              pollingToggle.turnOff();
              return;
            }
            pollAndReplace();
          })
      );
    }
    pollAndReplace();
    return () => {
      controller.abort();
    };
  }, [pollingToggle, account.id]);

  function handleSignInClick(e) {
    e.preventDefault();
    pollingToggle.turnOn();
    api
      .configurePrivateAccount({ id: account.id })
      .then(async (r) => {
        try {
          await makeAuthRequest(r.data.authRequest);
        } catch (e) {
          console.error(e);
          return Promise.reject(t("private_accounts.auth_error"));
        }
        await api.requestedPrivateAccountAccessCode({ id: account.id });
        pollingCallback();
      })
      .catch((e) => {
        setError(e);
        pollingToggle.turnOff();
      });
  }

  let content;
  if (pollingToggle.isOff) {
    content = (
      <Button className="mt-3" onClick={handleSignInClick}>
        {t("private_accounts:sign_in")}
      </Button>
    );
  } else {
    content = (
      <Stack direction="vertical">
        <Alert variant="light" className="bg-white border-0 pb-0">
          <p className="mt-3 mb-0 text-muted">{t("private_accounts:username")}</p>
          <Copyable inline className="lead mb-0" text={address} />
        </Alert>
        <Alert variant="info">
          <p className="lead mb-0">
            {t("private_accounts:signing_in")}
            <img
              src={loaderRing}
              width="80"
              height="80"
              alt={t("private_accounts:signing_in")}
            />
          </p>
        </Alert>
      </Stack>
    );
  }
  return (
    <Stack direction="vertical" className="align-items-start">
      <SumaImage
        image={vendorImage}
        height={80}
        params={{ crop: "none", fmt: "png", flatten: [255, 255, 255] }}
      />
      {content}
      <FormError error={error} className="mt-2" />
    </Stack>
  );
}

function makeAuthRequest({ url, httpMethod, params, headers, contentType }) {
  let body;
  if (httpMethod === "GET") {
    body = null;
  } else if (contentType.includes("/json")) {
    body = JSON.stringify(params);
  } else if (contentType.includes("www-form-urlencoded")) {
    body = new FormData();
    forEach((v, k) => body.append(k, v));
  }
  let h = { ...headers };
  h["Content-Type"] = contentType;
  return fetch(url, { method: httpMethod, headers, body }).then((r) => {
    if (r.status >= 400) {
      console.error("Error making auth request:", r.status, r);
      return Promise.reject();
    } else {
      return Promise.resolve();
    }
  });
}
