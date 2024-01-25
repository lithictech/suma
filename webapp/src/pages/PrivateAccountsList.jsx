import api from "../api";
import loaderRing from "../assets/images/loader-ring.svg";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import ErrorScreen from "../components/ErrorScreen";
import FormError from "../components/FormError";
import LayoutContainer from "../components/LayoutContainer";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import SumaMarkdown from "../components/SumaMarkdown";
import { mdp, t } from "../localization";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useMountEffect from "../shared/react/useMountEffect";
import { useError } from "../state/useError";
import { CanceledError } from "axios";
import get from "lodash/get";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Modal from "react-bootstrap/Modal";
import Stack from "react-bootstrap/Stack";

export default function PrivateAccountsList() {
  const {
    state: accounts,
    loading: accountsLoading,
    error: accountsError,
  } = useAsyncFetch(api.getPrivateAccounts, {
    default: {},
    pickData: true,
  });

  const [modalAccount, setModalAccount] = React.useState(null);

  useMountEffect(() => {
    // It's important that we dismiss the modal when the page loses focus.
    // That is an indication usually that the user has opened the vendor's native app
    // from the instructions modal.
    const handleVizChange = () => {
      setModalAccount(null);
    };
    document.addEventListener("visibilitychange", handleVizChange);
    return () => {
      document.removeEventListener("visibilitychange", handleVizChange);
    };
  });

  if (accountsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }

  const handleHelp = (o) => {
    setModalAccount(o);
  };

  return (
    <>
      <LayoutContainer gutters top>
        <LinearBreadcrumbs back="/dashboard" />
        <h2>{t("titles:private_accounts")}</h2>
        <p className="text-secondary">{t("private_accounts:intro")}</p>
      </LayoutContainer>
      <hr className="my-4" />
      <Modal show={!!modalAccount} onHide={() => setModalAccount(null)}>
        <Modal.Header closeButton>
          <Modal.Title>
            {t("private_accounts:vendor_private_accounts", {
              vendorName: modalAccount?.vendorName,
            })}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <div className="d-flex justify-content-center align-items-center flex-column m-2">
            <ScrollTopOnMount />
            <SumaMarkdown>{modalAccount?.instructions}</SumaMarkdown>
            <div className="d-flex justify-content-end mt-2">
              <Button variant="outline-primary" onClick={() => setModalAccount(null)}>
                {t("common:close")}
              </Button>
            </div>
          </div>
        </Modal.Body>
      </Modal>
      {accountsLoading ? (
        <PageLoader />
      ) : !isEmpty(accounts.items) ? (
        <LayoutContainer gutters>
          <Stack gap={3}>
            {accounts.items.map((a) => (
              <Card key={a.id}>
                <Card.Body>
                  <PrivateAccount account={a} onHelp={() => handleHelp(a)} />
                </Card.Body>
              </Card>
            ))}
          </Stack>
        </LayoutContainer>
      ) : (
        <LayoutContainer>{mdp("private_accounts:no_private_accounts")}</LayoutContainer>
      )}
    </>
  );
}

function PrivateAccount({ account, onHelp }) {
  const { vendorImage } = account;
  const [buttonStatus, setButtonStatus] = React.useState(INITIAL);
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
              window.setTimeout(() => setButtonStatus(SUCCESS), 100);
            } else {
              pollAndReplace();
            }
          })
          .catch((r) => {
            // If the request was aborted (due to unmount), don't restart it.
            // Otherwise, do restart it, since it is some unexpected type of error.
            if (r instanceof CanceledError) {
              setButtonStatus(INITIAL);
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
  }, [account.id]);

  function handleInitialClick(e) {
    e.preventDefault();
    setError(null);
    setButtonStatus(POLLING);
    api
      .configurePrivateAccount({ id: account.id })
      .then(async () => {
        try {
          await api.makePrivateAccountAuthRequest({ id: account.id });
        } catch (e) {
          console.error(get(e, "response.data") || e);
          return Promise.reject(<span>{t("private_accounts.auth_error")}</span>);
        }
        pollingCallback();
      })
      .catch((e) => {
        setError(e);
        setButtonStatus(INITIAL);
      });
  }

  let content;
  if (buttonStatus === INITIAL) {
    content = (
      <Stack direction="horizontal" gap={2} className="justify-content-center mb-1">
        <Button onClick={handleInitialClick}>{t("private_accounts:initial")}</Button>
        <Button variant="outline-primary" onClick={() => onHelp()}>
          {t("common:help")}
        </Button>
      </Stack>
    );
  } else if (buttonStatus === POLLING) {
    content = (
      <Alert variant="info" className="w-100 mb-0">
        <Stack direction="horizontal" gap={3}>
          <div className="me-auto">
            <h5>{t("private_accounts:polling")}</h5>
            <p>{t("private_accounts:polling_detail")}</p>
          </div>
          <img
            src={loaderRing}
            width="80"
            height="80"
            alt={t("private_accounts:polling")}
          />
        </Stack>
      </Alert>
    );
  } else {
    content = (
      <Alert variant="success" className="mb-0">
        <Stack direction="horizontal" gap={3}>
          {t("private_accounts:success")}
          <div className="ms-auto">
            <AnimatedCheckmark />
          </div>
        </Stack>
      </Alert>
    );
  }
  return (
    <Stack direction="vertical" className="align-items-start">
      <SumaImage
        image={vendorImage}
        height={80}
        params={{ crop: "none", fmt: "png", flatten: [255, 255, 255] }}
        className="mb-3"
      />
      {content}
      <FormError error={error} className="mt-3" />
    </Stack>
  );
}

const INITIAL = 1;
const POLLING = 2;
const SUCCESS = 3;
