import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FormButtons from "../components/FormButtons.jsx";
import FormError from "../components/FormError.jsx";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink.jsx";
import SumaMarkdown from "../components/SumaMarkdown.jsx";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useUnmountEffect from "../shared/react/useUnmountEffect.jsx";
import { useError } from "../state/useError.jsx";
import { CanceledError } from "axios";
import clsx from "clsx";
import get from "lodash/get";
import React from "react";
import { ProgressBar } from "react-bootstrap";
import Alert from "react-bootstrap/Alert";
import { useParams } from "react-router-dom";

/**
 * This is a pretty complicated page with several 'modes':
 * - When the user arrives, show them the overview of steps, which is in one of the following states:
 * - 1) Review terms, 2) link account,
 * - 1) Add payment method (unchecked), 2) review terms, 3) link account
 *   - When pressing Next, go to 'add card' screen, then back here;
 *     this will result in the 'checked' case
 *     (we could in the future go to the 'terms' screen directly).
 * - 1) Add payment method (checked), 2) review terms, 3) link account
 * - Press 'next' and see the 'review terms' screen (submits the /process endpoint)
 * - End up on the 'link account' screen.
 * - Press 'link', which does the request polling.
 * - Provide 'View private accounts' button.
 */
export default function PrivateAccountDetail() {
  const { id } = useParams();
  const makeRequest = React.useCallback(
    () => api.processPrivateAccountDetail({ id }),
    [id]
  );
  const {
    state: account,
    loading: accountLoading,
    error: accountError,
  } = useAsyncFetch(makeRequest, {
    default: {},
    pickData: true,
  });
  const [view, setView] = React.useState(VIEW_STEPS);

  if (accountError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (accountLoading) {
    return (
      <LayoutContainer gutters top>
        <PageLoader />
      </LayoutContainer>
    );
  }
  if (view === VIEW_TERMS) {
    return <TermsView account={account} setView={setView} />;
  } else if (view === VIEW_LINK) {
    return <LinkView account={account} setView={setView} />;
  }
  return <StepsView account={account} setView={setView} />;
}

/**
 * @param {AnonProxyVendorAccount} account
 * @param setView
 */
function StepsView({ account, setView }) {
  const primaryProps = { children: t("common.next"), variant: "primary" };
  if (account.uiStateV1.requiresPaymentMethod && !account.uiStateV1.hasPaymentMethod) {
    primaryProps.as = RLink;
    primaryProps.to = `/add-card?returnToImmediate=/private-account/${account.id}`;
  } else {
    primaryProps.onClick = () => setView(VIEW_TERMS);
  }
  const secondStepNumber = account.uiStateV1.requiresPaymentMethod ? 2 : 1;

  return (
    <ProgressContainer header={t("private_accounts.view_header_steps")} view={VIEW_STEPS}>
      <ul className="list-unstyled mb-0">
        {account.uiStateV1.requiresPaymentMethod && (
          <li>
            <i
              className={clsx(
                "me-2",
                "bi",
                account.uiStateV1.hasPaymentMethod
                  ? "bi-check-square-fill"
                  : "bi-1-square"
              )}
            />
            {t("private_accounts.checklist_setup_payment")}
          </li>
        )}
        <li>
          <i className={clsx("me-2", `bi bi-${secondStepNumber}-square`)} />
          {t("private_accounts.checklist_review_terms")}
        </li>
        <li>
          <i className={clsx("me-2", `bi bi-${secondStepNumber + 1}-square`)} />
          {t("private_accounts.checklist_link_app")}
        </li>
      </ul>
      <FormButtons margin={0} back primaryProps={primaryProps} />
    </ProgressContainer>
  );
}

/**
 * @param {AnonProxyVendorAccount} account
 * @param setView
 */
function TermsView({ account, setView }) {
  return (
    <ProgressContainer header={t("private_accounts.view_header_terms")} view={VIEW_TERMS}>
      <SumaMarkdown>{account.uiStateV1.termsText}</SumaMarkdown>
      <FormButtons
        margin={0}
        secondaryProps={{
          children: "Back",
          onClick: () => setView(VIEW_STEPS),
        }}
        primaryProps={{
          children: "Agree",
          variant: "primary",
          onClick: () => setView(VIEW_LINK),
        }}
      />
    </ProgressContainer>
  );
}

/**
 * @param {AnonProxyVendorAccount} account
 * @param setView
 */
function LinkView({ account, setView }) {
  const pollingController = React.useRef(new AbortController());
  const [buttonStatus, setButtonStatus] = React.useState(LINKBTN_INITIAL);
  const [error, setError] = useError(null);
  const [pollingSuccessResponse, setPollingSuccessResponse] = React.useState(null);

  useUnmountEffect(() => {
    pollingController.current.abort();
  });

  const pollingCallback = React.useCallback(() => {
    pollingController.current.abort();
    pollingController.current = new AbortController();
    function pollAndReplace() {
      return (
        api
          // Poll with a timeout, in case the server stops responding we want to try again.
          .pollForNewPrivateAccountMagicLink(
            { id: account.id },
            { timeout: 30000, signal: pollingController.current.signal }
          )
          .then((r) => {
            if (r.data.foundChange) {
              setPollingSuccessResponse(r.data);
              setButtonStatus(LINKBTN_SENT);
            } else {
              pollAndReplace();
            }
          })
          .catch((r) => {
            // If the request was aborted (due to unmount), don't restart it.
            // Otherwise, do restart it, since it is some unexpected type of error.
            if (r instanceof CanceledError) {
              setButtonStatus(LINKBTN_INITIAL);
              return;
            }
            pollAndReplace();
          })
      );
    }
    pollAndReplace();
  }, [account.id]);

  function handleInitialClick(e) {
    e.preventDefault();
    setPollingSuccessResponse(null);
    setError(null);
    setButtonStatus(LINKBTN_POLLING);
    api
      .makePrivateAccountAuthRequest({ id: account.id })
      .then(pollingCallback)
      .catch((e) => {
        console.error(get(e, "response.data") || e);
        setError(<span>{t("private_accounts.auth_error")}</span>);
        setButtonStatus(LINKBTN_INITIAL);
      });
  }

  let primaryBtnProps, secondaryBtnProps, alertVariant;
  if (buttonStatus === LINKBTN_SENT) {
    primaryBtnProps = null;
    secondaryBtnProps = {
      children: t("private_accounts.linkview_back_to_list"),
      as: RLink,
      to: `/private-accounts`,
    };
    alertVariant = "success";
  } else if (buttonStatus === LINKBTN_POLLING) {
    primaryBtnProps = {
      children: t("private_accounts.linkview_polling"),
      variant: "primary",
      disabled: true,
    };
    secondaryBtnProps = {
      children: t("common.cancel"),
      onClick: () => setView(VIEW_STEPS),
    };
    alertVariant = "info";
  } else {
    primaryBtnProps = {
      children: t("private_accounts.linkview_link_app"),
      variant: "primary",
      onClick: handleInitialClick,
    };
    secondaryBtnProps = {
      children: t("common.back"),
      onClick: () => setView(VIEW_STEPS),
    };
  }

  return (
    <ProgressContainer
      header={t("private_accounts.view_header_link")}
      view={VIEW_LINK}
      progress={buttonStatus === LINKBTN_SENT ? 100 : null}
    >
      <SumaMarkdown>{t("private_accounts.linkview_instructions")}</SumaMarkdown>
      <Alert variant={alertVariant} show={!!alertVariant} className="mb-0">
        {buttonStatus === LINKBTN_SENT ? (
          <span>
            <i className="bi bi-phone-vibrate d-inline me-2"></i>
            {pollingSuccessResponse?.successInstructions}
          </span>
        ) : (
          <div>
            <PageLoader containerClass="d-inline-block me-3" height={30} />
            {t("private_accounts.linkview_polling_detail")}
          </div>
        )}
      </Alert>
      <FormError error={error} />
      <FormButtons
        margin={0}
        secondaryProps={secondaryBtnProps}
        primaryProps={primaryBtnProps}
      />
    </ProgressContainer>
  );
}

const LINKBTN_INITIAL = "link-init";
const LINKBTN_POLLING = "link-polling";
const LINKBTN_SENT = "link-sent";

/**
 * @param {string} header
 * @param {string} view
 * @param {number=} progress
 * @param children
 */
function ProgressContainer({ header, view, progress, children }) {
  if (!progress) {
    progress = { [VIEW_STEPS]: 20, [VIEW_TERMS]: 60, [VIEW_LINK]: 80 }[view];
  }
  return (
    <LayoutContainer gutters className="d-flex flex-column gap-4">
      <ProgressBar now={progress} variant="info" className="mt-3" />
      <h2 className="mb-0">{header}</h2>
      {children}
    </LayoutContainer>
  );
}

const VIEW_STEPS = "steps";
const VIEW_TERMS = "terms";
const VIEW_LINK = "link";
