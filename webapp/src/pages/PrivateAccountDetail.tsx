import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import { dt, t } from "../localization";
import { scaleMoney } from "../modules/money";
import useAsyncFetch from "../state/useAsyncFetch";
import { extractErrorCode, useError } from "../state/useError";
import useScreenLoader from "../state/useScreenLoader";
import useUnmountEffect from "../state/useUnmountEffect";
import useUser from "../state/useUser";
import Alert from "../ui/Alert";
import FormButtons from "../ui/FormButtons";
import FormError from "../ui/FormError";
import Progress from "../ui/Progress";
import { CanceledError } from "axios";
import clsx from "clsx";
import React from "react";
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
  } = useAsyncFetch<AnonProxyVendorAccount>(makeRequest, {
    default: {} as AnonProxyVendorAccount,
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
  if (view === VIEW_BALANCE) {
    return <BalanceView setView={setView} />;
  } else if (view === VIEW_TERMS) {
    return <TermsView account={account} setView={setView} />;
  } else if (view === VIEW_LINK) {
    return <LinkView account={account} setView={setView} />;
  }
  return <StepsView account={account} setView={setView} />;
}

function StepsView({
  account,
  setView,
}: {
  account: AnonProxyVendorAccount;
  setView: (view: string) => void;
}) {
  const {
    requiresPaymentMethod,
    hasPaymentMethod,
    balancePayoffNeeded,
    termStepIndex,
    linkStepIndex,
  } = account.uiStateV1;

  const primaryProps: Record<string, any> = {
    children: t("common.next"),
    variant: "primary",
  };
  if (account.uiStateV1.requiresPaymentMethod && !account.uiStateV1.hasPaymentMethod) {
    primaryProps.to = `/add-card?returnToImmediate=/private-account/${account.id}`;
  } else {
    const nextView = balancePayoffNeeded ? VIEW_BALANCE : VIEW_TERMS;
    primaryProps.onClick = () => setView(nextView);
  }
  let potentialFirstStep;
  if (requiresPaymentMethod) {
    let checked, locKey;
    if (balancePayoffNeeded) {
      locKey = "private_accounts.checklist_pay_balance";
      checked = false;
    } else if (!hasPaymentMethod) {
      locKey = "private_accounts.checklist_setup_payment";
      checked = false;
    } else {
      locKey = "private_accounts.checklist_setup_payment";
      checked = true;
    }
    potentialFirstStep = (
      <li>
        <i
          className={clsx("me-2", "bi", checked ? "bi-check-square-fill" : "bi-1-square")}
        />
        {t(locKey)}
      </li>
    );
  }

  return (
    <ProgressContainer progress={20} header={t("private_accounts.view_header_steps")}>
      <ul className="list-unstyled mb-0">
        {potentialFirstStep}
        <li>
          <i className={clsx("me-2", `bi bi-${termStepIndex + 1}-square`)} />
          {t("private_accounts.checklist_review_terms")}
        </li>
        <li>
          <i className={clsx("me-2", `bi bi-${linkStepIndex + 1}-square`)} />
          {t("private_accounts.checklist_link_app")}
        </li>
      </ul>
      <FormButtons margin={0} back primaryProps={primaryProps} />
    </ProgressContainer>
  );
}

function BalanceView({ setView }: { setView: (view: string) => void }) {
  const { user, setUser } = useUser();
  const [error, setError] = useError();
  const screenLoader = useScreenLoader();

  function handleClick(e: React.MouseEvent) {
    screenLoader.turnOn();
    setError(null);
    e.preventDefault();
    api
      .chargeLedgerBalance()
      .then((r: any) => {
        setUser(r.data);
        setView(VIEW_TERMS);
      })
      .catch((e: any) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  }

  const balance = scaleMoney(user.chargeableCashBalance, -1);

  return (
    <ProgressContainer progress={40} header={t("private_accounts.checklist_pay_balance")}>
      <div>{t("private_accounts.pay_balance_explanation", { amount: balance })}</div>
      <FormError error={error} noMargin />
      <FormButtons
        margin={0}
        secondaryProps={{
          children: t("common.back"),
          onClick: () => setView(VIEW_STEPS),
        }}
        primaryProps={{
          children: t("payments.negative_balance_action", { amount: balance }),
          variant: "danger",
          onClick: handleClick,
        }}
      />
    </ProgressContainer>
  );
}

function TermsView({
  account,
  setView,
}: {
  account: AnonProxyVendorAccount;
  setView: (view: string) => void;
}) {
  return (
    <ProgressContainer progress={60} header={t("private_accounts.view_header_terms")}>
      {dt(account.uiStateV1.termsText)}
      <FormButtons
        margin={0}
        secondaryProps={{
          children: t("common.back"),
          onClick: () => setView(VIEW_STEPS),
        }}
        primaryProps={{
          children: t("common.agree"),
          variant: "primary",
          onClick: () => setView(VIEW_LINK),
        }}
      />
    </ProgressContainer>
  );
}

function LinkView({
  account,
  setView,
}: {
  account: AnonProxyVendorAccount;
  setView: (view: string) => void;
}) {
  const pollingController = React.useRef(new AbortController());
  const [buttonStatus, setButtonStatus] = React.useState(LINKBTN_INITIAL);
  const [error, setError] = useError(null);
  const [pollingSuccessResponse, setPollingSuccessResponse] =
    React.useState<AnonProxyVendorAccountPollResult | null>(null);

  useUnmountEffect(() => {
    pollingController.current.abort();
  });

  const pollingCallback = React.useCallback(() => {
    pollingController.current.abort();
    pollingController.current = new AbortController();
    function pollAndReplace(): any {
      return (
        api
          // Poll with a timeout, in case the server stops responding we want to try again.
          .pollForNewPrivateAccountMagicLink(
            { id: account.id },
            { timeout: 30000, signal: pollingController.current.signal }
          )
          .then((r: any) => {
            if (r.data.foundChange) {
              setPollingSuccessResponse(r.data);
              setButtonStatus(LINKBTN_SENT);
            } else {
              pollAndReplace();
            }
          })
          .catch((r: any) => {
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

  function handleInitialClick(e: React.MouseEvent) {
    e.preventDefault();
    setPollingSuccessResponse(null);
    setError(null);
    setButtonStatus(LINKBTN_POLLING);
    api
      .makePrivateAccountAuthRequest({ id: account.id })
      .then(pollingCallback)
      .catch(() => {
        setError(<span>{t("private_accounts.auth_error")}</span>);
        setButtonStatus(LINKBTN_INITIAL);
      });
  }

  let primaryBtnProps: Record<string, any> | null,
    secondaryBtnProps: Record<string, any>,
    alertVariant: string | undefined;
  if (buttonStatus === LINKBTN_SENT) {
    primaryBtnProps = null;
    secondaryBtnProps = {
      children: t("private_accounts.linkview_back_to_list"),
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
      progress={buttonStatus === LINKBTN_SENT ? 100 : 80}
      header={t("private_accounts.view_header_link")}
    >
      {t("private_accounts.linkview_instructions")}
      <Alert variant={alertVariant} show={!!alertVariant} className="mb-0">
        {buttonStatus === LINKBTN_SENT ? (
          <span>
            <i className="bi bi-phone-vibrate d-inline me-2"></i>
            {dt(pollingSuccessResponse?.successInstructions)}
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

function ProgressContainer({
  header,
  progress,
  children,
}: {
  header: React.ReactNode;
  progress: number;
  children?: React.ReactNode;
}) {
  return (
    <LayoutContainer gutters className="d-flex flex-column gap-4">
      <Progress value={progress} className="mt-3" />
      <h2 className="mb-0">{header}</h2>
      {children}
    </LayoutContainer>
  );
}

const VIEW_STEPS = "steps";
const VIEW_BALANCE = "balance";
const VIEW_TERMS = "terms";
const VIEW_LINK = "link";
