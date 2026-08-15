import api from "../api";
import bankAccountCheckDetails from "../assets/images/bank-account-check-details.gif";
import BackBreadcrumb from "../components/BackBreadcrumb";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import FormText from "../components/FormText";
import GoHome from "../components/GoHome";
import PageHeading from "../components/PageHeading";
import config from "../config";
import { imageAltT, t } from "../localization";
import keepDigits from "../modules/keepDigits";
import { extractErrorCode, useError } from "../state/useError";
import useHashToggle from "../state/useHashToggle";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import Button from "../ui/Button";
import Col from "../ui/Col";
import { Dialog } from "../ui/Dialog";
import DialogHeader from "../ui/DialogHeader";
import Form from "../ui/Form";
import FormCheck from "../ui/FormCheck";
import FormGroup from "../ui/FormGroup";
import FormLabel from "../ui/FormLabel";
import Row from "../ui/Row";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useForm } from "react-hook-form";
import { useSearchParams } from "react-router-dom";

type LinkedBankAccount = Omit<SuccessProps, "returnTo">;

export default function FundingLinkBankAccount() {
  const [submitSuccessful, setSubmitSuccessful] = React.useState<
    LinkedBankAccount | Record<string, never>
  >({});
  const [params] = useSearchParams();
  const returnTo = params.get("returnTo");
  return (
    <>
      {!isEmpty(submitSuccessful) ? (
        <Success {...(submitSuccessful as LinkedBankAccount)} returnTo={returnTo} />
      ) : (
        <LinkBankAccount
          onSuccess={(bankAccountData: LinkedBankAccount) =>
            setSubmitSuccessful({ ...bankAccountData })
          }
          returnTo={returnTo}
        />
      )}
    </>
  );
}

interface SuccessProps {
  instrumentId: number;
  instrumentType: string;
  returnTo: string | null;
}

function Success({ instrumentId, instrumentType, returnTo }: SuccessProps) {
  return (
    <>
      <h2>{t("payments.linked_bank_account")}</h2>
      {t("payments.linked_bank_account_successful")}
      {returnTo ? (
        <div className="button-stack mt-4">
          <Button
            href={`${returnTo}?instrumentId=${instrumentId}&instrumentType=${instrumentType}`}
            variant="outline"
          >
            {t("forms.continue")}
          </Button>
        </div>
      ) : (
        <GoHome />
      )}
    </>
  );
}

interface LinkBankAccountProps {
  onSuccess: (bankAccountData: LinkedBankAccount) => void;
  returnTo: string | null;
}

function LinkBankAccount({ onSuccess, returnTo }: LinkBankAccountProps) {
  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });
  const [error, setError] = useError();
  const { user, setUser, handleUpdateCurrentMember } = useUser();

  const screenLoader = useScreenLoader();
  const showCheckModalToggle = useHashToggle("check-details");
  const [nickname, setNickname] = React.useState(config.devBankAccountDetails.name || "");
  const [routing, setRouting] = React.useState(
    config.devBankAccountDetails.routing || ""
  );
  const [accountNumber, setAccountNumber] = React.useState(
    config.devBankAccountDetails.account || ""
  );
  const [accountNumberConfirm, setAccountNumberConfirm] = React.useState(
    config.devBankAccountDetails.account || ""
  );
  const [accountType, setAccountType] = React.useState("checking");

  const handleFormSubmit = () => {
    screenLoader.turnOn();
    api
      .createBankAccount({
        name: nickname,
        routingNumber: routing,
        accountNumber,
        accountType,
      })
      .tap(handleUpdateCurrentMember)
      .then((r: any) => {
        setUser({ ...user, paymentInstruments: r.data.allPaymentInstruments });
        onSuccess({ instrumentId: r.data.id, instrumentType: r.data.paymentMethodType });
      })
      .catch((e: any) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  };
  const runSetter = (name: string, set: (value: string) => void, value: string) => {
    clearErrors(name);
    setValue(name, value);
    set(value);
  };

  return (
    <>
      <BackBreadcrumb back={returnTo || true} />
      <PageHeading>{t("payments.link_bank_account")}</PageHeading>
      <p>{t("payments.payment_intro.privacy_statement")}</p>
      <Form noValidate onSubmit={handleSubmit(handleFormSubmit)}>
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            required
            type="text"
            name="nickname"
            label={t("forms.nickname")}
            text={t("forms.nickname_caption")}
            value={nickname}
            errors={errors}
            register={register}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              runSetter(e.target.name, setNickname, e.target.value)
            }
          />
        </Row>
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            required
            type="text"
            pattern="^[0-9]{9}$"
            inputMode="numeric"
            name="routing_number"
            label={t("forms.routing_number")}
            text={t("forms.routing_caption")}
            value={routing}
            errors={errors}
            errorKeys={{ pattern: "forms.invalid_routing_number" }}
            register={register}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              runSetter(e.target.name, setRouting, keepDigits(e.target.value))
            }
          />
        </Row>
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            required
            type="text"
            pattern="^\d{3}\d+$"
            inputMode="numeric"
            name="account_number"
            label={t("forms.account_number")}
            text={t("forms.bank_account_caption")}
            value={accountNumber}
            errors={errors}
            errorKeys={{ pattern: "forms.invalid_bank_account_number" }}
            register={register}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              runSetter(e.target.name, setAccountNumber, keepDigits(e.target.value))
            }
          />
        </Row>
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            required
            type="text"
            inputMode="numeric"
            name="confirm_account_number"
            label={t("forms.confirm_account_number")}
            text={t("forms.confirm_account_number_caption")}
            value={accountNumberConfirm}
            errors={errors}
            errorKeys={{ validate: "forms.invalid_bank_account_number_confirm" }}
            register={register}
            registerOptions={{ validate: (v: string) => v === accountNumber }}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              runSetter(
                e.target.name,
                setAccountNumberConfirm,
                keepDigits(e.target.value)
              )
            }
          />
        </Row>
        <Row className="mb-3">
          <FormGroup as={Col}>
            <FormLabel>{t("forms.bank_account_type")}</FormLabel>
            <div>
              <FormCheck
                inline
                id="cheking"
                name="account-type"
                type="radio"
                label={t("forms.checking")}
                checked={accountType === "checking"}
                onChange={() => setAccountType("checking")}
              />
              <FormCheck
                inline
                id="savings"
                name="account-type"
                type="radio"
                label={t("forms.savings")}
                checked={accountType === "savings"}
                onChange={() => setAccountType("savings")}
              />
            </div>
            <FormText>{t("forms.bank_account_type_caption")}</FormText>
          </FormGroup>
        </Row>

        <p>{t("payments.account_submission_statement")}</p>
        <FormError error={error} />
        <FormButtons
          variant="outline"
          back
          primaryProps={{
            children: t("forms.continue"),
          }}
        />
        <Dialog
          open={showCheckModalToggle.isOn}
          onClose={showCheckModalToggle.turnOff}
          labelledBy="check-details-modal-title"
        >
          <DialogHeader id="check-details-modal-title">
            {t("payments.check_details_title")}
          </DialogHeader>
          <p>{t("payments.check_details_subtitle")}</p>
          <img
            src={bankAccountCheckDetails}
            alt={imageAltT("check_detail_example")}
            className="w-100"
          />
        </Dialog>
      </Form>
    </>
  );
}
