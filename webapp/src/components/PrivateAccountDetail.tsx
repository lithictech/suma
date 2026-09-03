import { IdParams } from "../api.ts";
import { dt, t } from "../localization";
import { appError, AppError, extractAppErrorAny } from "../modules/feedback.ts";
import { scaleMoney } from "../modules/money.ts";
import { withQuery } from "../routing/withQuery.ts";
import { SetCurrentMember } from "../state/UserProvider.tsx";
import useAsyncFetch from "../state/useAsyncFetch.ts";
import useScreenLoader from "../state/useScreenLoader.ts";
import useUnmountEffect from "../state/useUnmountEffect.ts";
import Alert, { AlertVariant } from "../ui/Alert.tsx";
import { ButtonProps } from "../ui/Button.tsx";
import FormSubmit from "../ui/FormSubmit.tsx";
import IndeterminateLoader from "../ui/IndeterminateLoader.tsx";
import Page from "../ui/Page.tsx";
import Progress from "../ui/Progress.tsx";
import AsyncContent from "./AsyncContent.tsx";
import { AxiosRequestConfig, AxiosResponse, CanceledError } from "axios";
import clsx from "clsx";
import React from "react";

export interface PrivateAccountDetailApiCalls {
  processAccount: (
    params: IdParams,
    cfg?: AxiosRequestConfig
  ) => Promise<AxiosResponse<AnonProxyVendorAccount>>;
  chargeLedgerBalance: () => Promise<AxiosResponse<CurrentMember>>;
  pollForNewPrivateAccountMagicLink: (
    p: IdParams,
    cfg?: AxiosRequestConfig
  ) => Promise<AxiosResponse<AnonProxyVendorAccountPollResult>>;
  makeAuthRequest: (
    p: IdParams,
    cfg?: AxiosRequestConfig
  ) => Promise<AxiosResponse<AnonProxyVendorAccount>>;
}

export interface PrivateAccountDetailProps {
  id: number;
  apiCalls: PrivateAccountDetailApiCalls;
  user: CurrentMember;
  setUser: SetCurrentMember;
}

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
export default function PrivateAccountDetail({
  id,
  apiCalls,
  user,
  setUser,
}: PrivateAccountDetailProps) {
  const makeRequest = React.useCallback(
    () => apiCalls.processAccount({ id }),
    [apiCalls, id]
  );
  const { state, loading, error } = useAsyncFetch<AnonProxyVendorAccount>(makeRequest);
  const [view, setView] = React.useState(VIEW_STEPS);

  return (
    <AsyncContent loading={loading} error={error}>
      {() => {
        const account = state!;
        const props = { account, setView, apiCalls, user, setUser };
        if (view === VIEW_BALANCE) {
          return <BalanceView {...props} />;
        } else if (view === VIEW_TERMS) {
          return <TermsView {...props} />;
        } else if (view === VIEW_LINK) {
          return <LinkView {...props} />;
        }
        return <StepsView {...props} />;
      }}
    </AsyncContent>
  );
}

interface ViewProps {
  account: AnonProxyVendorAccount;
  setView: (view: string) => void;
  apiCalls: PrivateAccountDetailApiCalls;
  user: CurrentMember;
  setUser: SetCurrentMember;
}

function StepsView({ account, setView }: ViewProps) {
  const {
    requiresPaymentMethod,
    hasPaymentMethod,
    balancePayoffNeeded,
    termStepIndex,
    linkStepIndex,
  } = account.uiStateV1;

  const primaryProps: ButtonProps = {
    children: t("common.next"),
    preset: "primary",
  };
  if (account.uiStateV1.requiresPaymentMethod && !account.uiStateV1.hasPaymentMethod) {
    primaryProps.to = withQuery(`/add-card`, {
      returnToImmediate: `/private-account/${account.id}`,
    });
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
      <FormSubmit back primary={primaryProps} />
    </ProgressContainer>
  );
}

function BalanceView({ setView, apiCalls, user, setUser }: ViewProps) {
  const [error, setError] = React.useState<AppError | null>();
  const screenLoader = useScreenLoader();

  function handleClick(e: React.MouseEvent) {
    screenLoader.turnOn();
    setError(null);
    e.preventDefault();
    apiCalls
      .chargeLedgerBalance()
      .then((r) => {
        setUser(r.data);
        setView(VIEW_TERMS);
      })
      .catch((e: any) => setError(extractAppErrorAny(e)))
      .finally(screenLoader.turnOff);
  }

  const balance = scaleMoney(user.chargeableCashBalance!, -1);

  return (
    <ProgressContainer progress={40} header={t("private_accounts.checklist_pay_balance")}>
      <div>{t("private_accounts.pay_balance_explanation", { amount: balance })}</div>
      <FormSubmit
        feedback={error}
        secondary={{
          children: t("common.back"),
          onClick: () => setView(VIEW_STEPS),
        }}
        primary={{
          children: t("payments.negative_balance_action", { amount: balance }),
          variant: "filled",
          color: "danger",
          onClick: handleClick,
        }}
      />
    </ProgressContainer>
  );
}

function TermsView({ account, setView }: ViewProps) {
  return (
    <ProgressContainer progress={60} header={t("private_accounts.view_header_terms")}>
      {dt(account.uiStateV1.termsText)}
      <FormSubmit
        secondary={{
          children: t("common.back"),
          onClick: () => setView(VIEW_STEPS),
        }}
        primary={{
          children: t("common.agree"),
          onClick: () => setView(VIEW_LINK),
        }}
      />
    </ProgressContainer>
  );
}

function LinkView({ account, setView, apiCalls }: ViewProps) {
  const pollingController = React.useRef(new AbortController());
  const [buttonStatus, setButtonStatus] = React.useState(LINKBTN_INITIAL);
  const [error, setError] = React.useState<AppError | null>();
  const [pollingSuccessResponse, setPollingSuccessResponse] =
    React.useState<AnonProxyVendorAccountPollResult | null>(null);

  useUnmountEffect(() => {
    pollingController.current.abort();
  });

  const pollingCallback = React.useCallback(() => {
    pollingController.current.abort();
    pollingController.current = new AbortController();
    function pollAndReplace() {
      return (
        apiCalls
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
  }, [account.id, apiCalls]);

  function handleInitialClick(e: React.MouseEvent) {
    e.preventDefault();
    setPollingSuccessResponse(null);
    setError(null);
    setButtonStatus(LINKBTN_POLLING);
    apiCalls
      .makeAuthRequest({ id: account.id })
      .then(pollingCallback)
      .catch(() => {
        setError(appError("private_accounts.auth_error"));
        setButtonStatus(LINKBTN_INITIAL);
      });
  }

  let primaryBtnProps: ButtonProps;
  let secondaryBtnProps: object | null;
  let alertVariant: AlertVariant | null = null;
  if (buttonStatus === LINKBTN_SENT) {
    primaryBtnProps = {};
    secondaryBtnProps = {
      children: t("private_accounts.linkview_back_to_list"),
      to: `/private-accounts`,
    };
    alertVariant = "success";
  } else if (buttonStatus === LINKBTN_POLLING) {
    primaryBtnProps = {
      children: t("private_accounts.linkview_polling"),
      variant: "filled",
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
      variant: "filled",
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
      {alertVariant && (
        <Alert
          variant={alertVariant!}
          text={
            buttonStatus === LINKBTN_SENT ? (
              <span>
                <i className="bi bi-phone-vibrate d-inline me-2"></i>
                {dt(pollingSuccessResponse?.successInstructions || "")}
              </span>
            ) : (
              <div>
                <IndeterminateLoader variant="plain" size={30} />
                {t("private_accounts.linkview_polling_detail")}
              </div>
            )
          }
        />
      )}
      <FormSubmit
        feedback={error}
        primary={primaryBtnProps}
        secondary={secondaryBtnProps}
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
    <Page>
      <Progress value={progress} />
      <h2>{header}</h2>
      {children}
    </Page>
  );
}

const VIEW_STEPS = "steps";
const VIEW_BALANCE = "balance";
const VIEW_TERMS = "terms";
const VIEW_LINK = "link";
