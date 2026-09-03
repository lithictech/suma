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
import Checklist from "../ui/Checklist.tsx";
import ChecklistItem from "../ui/ChecklistItem.tsx";
import FormSubmit from "../ui/FormSubmit.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import ProgressStepHeader from "../ui/ProgressStepHeader.tsx";
import AsyncContent from "./AsyncContent.tsx";
import { DevicePhoneMobileIcon } from "@heroicons/react/24/outline";
import { AxiosRequestConfig, AxiosResponse, CanceledError } from "axios";
import React from "react";

export type PrivateAccountDetailStep = "steps" | "balance" | "terms" | "link";

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
  /** For demo purposes. */
  initialStep?: PrivateAccountDetailStep;
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
  initialStep,
}: PrivateAccountDetailProps) {
  const makeRequest = React.useCallback(
    () => apiCalls.processAccount({ id }),
    [apiCalls, id]
  );
  const { state, loading, error } = useAsyncFetch<AnonProxyVendorAccount>(makeRequest);
  const [view, setView] = React.useState<PrivateAccountDetailStep>(
    initialStep || "steps"
  );

  return (
    <AsyncContent loading={loading} error={error}>
      {() => {
        const account = state!;
        const props = { account, setView, apiCalls, user, setUser };
        if (view === "balance") {
          return <BalanceView {...props} />;
        } else if (view === "terms") {
          return <TermsView {...props} />;
        } else if (view === "link") {
          return <LinkView {...props} />;
        }
        return <StepsView {...props} />;
      }}
    </AsyncContent>
  );
}

interface ViewProps {
  account: AnonProxyVendorAccount;
  setView: (view: PrivateAccountDetailStep) => void;
  apiCalls: PrivateAccountDetailApiCalls;
  user: CurrentMember;
  setUser: SetCurrentMember;
}

function StepsView({ account, setView }: ViewProps) {
  const { requiresPaymentMethod, hasPaymentMethod, balancePayoffNeeded } =
    account.uiStateV1;

  const primaryProps: ButtonProps = {
    children: t("common.next"),
    preset: "primary",
  };
  if (requiresPaymentMethod && !hasPaymentMethod) {
    primaryProps.to = withQuery(`/add-card`, {
      returnToImmediate: `/private-account/${account.id}`,
    });
  } else {
    const nextView = balancePayoffNeeded ? "balance" : "terms";
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
      <ChecklistItem key={10} variant={checked ? "checked" : "current"}>
        {t(locKey)}
      </ChecklistItem>
    );
  }

  return (
    <Page>
      <PageHeader title={t("private_accounts.view_header_steps")} back />
      <Checklist>
        {potentialFirstStep}
        <ChecklistItem key={20} variant="future">
          {t("private_accounts.checklist_review_terms")}
        </ChecklistItem>
        <ChecklistItem key={30} variant="future">
          {t("private_accounts.checklist_link_app")}
        </ChecklistItem>
      </Checklist>
      <FormSubmit back primary={primaryProps} />
    </Page>
  );
}

function BalanceView({ account, setView, apiCalls, user, setUser }: ViewProps) {
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
        setView("terms");
      })
      .catch((e: any) => setError(extractAppErrorAny(e)))
      .finally(screenLoader.turnOff);
  }

  const balance = scaleMoney(user.chargeableCashBalance!, -1);

  return (
    <ProgressContainer
      step="balance"
      account={account}
      header={t("private_accounts.checklist_pay_balance")}
    >
      <div>{t("private_accounts.pay_balance_explanation", { amount: balance })}</div>
      <FormSubmit
        feedback={error}
        secondary={{
          children: t("common.back"),
          onClick: () => setView("steps"),
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
    <ProgressContainer
      step="terms"
      account={account}
      header={t("private_accounts.view_header_terms")}
    >
      {dt(account.uiStateV1.termsText)}
      <FormSubmit
        primary={{
          children: t("common.agree"),
          onClick: () => setView("link"),
        }}
        secondary={{
          children: t("common.back"),
          onClick: () => setView("steps"),
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
  let secondaryBtnProps: ButtonProps | null = null;
  let alertVariant: AlertVariant | null = null;
  if (buttonStatus === LINKBTN_SENT) {
    primaryBtnProps = {
      children: t("private_accounts.linkview_back_to_list"),
      to: `/private-accounts`,
      variant: "outline",
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
      onClick: () => setView("steps"),
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
      onClick: () => setView("steps"),
    };
  }

  return (
    <ProgressContainer
      account={account}
      step="link"
      header={t("private_accounts.view_header_link")}
    >
      {t("private_accounts.linkview_instructions")}
      {alertVariant && (
        <Alert
          variant={alertVariant!}
          icon={buttonStatus === LINKBTN_SENT ? DevicePhoneMobileIcon : "loader"}
          text={
            buttonStatus === LINKBTN_SENT
              ? dt(pollingSuccessResponse?.successInstructions || "")
              : t("private_accounts.linkview_polling_detail")
          }
        />
      )}
      <FormSubmit
        feedback={error}
        primary={primaryBtnProps}
        secondary={secondaryBtnProps || undefined}
      />
    </ProgressContainer>
  );
}

const LINKBTN_INITIAL = "link-init";
const LINKBTN_POLLING = "link-polling";
const LINKBTN_SENT = "link-sent";

function ProgressContainer({
  header,
  step,
  account,
  children,
}: {
  header: React.ReactNode;
  step: PrivateAccountDetailStep;
  account: AnonProxyVendorAccount;
  children?: React.ReactNode;
}) {
  let mapping: Record<PrivateAccountDetailStep, number>;
  let stepCount: number;
  if (account.uiStateV1.requiresPaymentMethod) {
    mapping = {
      steps: 0,
      balance: 1,
      terms: 2,
      link: 3,
    };
    stepCount = 3;
  } else {
    mapping = {
      steps: 0,
      balance: 0,
      terms: 1,
      link: 2,
    };
    stepCount = 2;
  }
  return (
    <Page>
      <ProgressStepHeader step={mapping[step]} steps={stepCount} />
      <h2>{header}</h2>
      {children}
    </Page>
  );
}
