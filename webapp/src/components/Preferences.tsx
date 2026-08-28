import { t } from "../localization";
import useI18n from "../localization/useI18n.ts";
import useBackendGlobals from "../state/useBackendGlobals.ts";
import useErrorToast from "../state/useErrorToast";
import useScreenLoader from "../state/useScreenLoader";
import BackButton from "../ui/BackButton.tsx";
import ButtonGroup from "../ui/ButtonGroup.tsx";
import Checkbox from "../ui/Checkbox.tsx";
import ContinueButton from "../ui/ContinueButton.tsx";
import Form from "../ui/Form";
import LanguageSwitcher from "../ui/LanguageSwitcher.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import has from "lodash/has";
import React from "react";

interface PreferencesProps {
  user: CurrentMember;
  onApiSubmit: (body: { subscriptions: Record<string, boolean> }) => Promise<any>;
  children?: React.ReactNode;
  onSaved: (response: any) => void;
}

export default function Preferences({
  user,
  onApiSubmit,
  children,
  onSaved,
}: PreferencesProps) {
  const { showErrorToast } = useErrorToast();
  const { supportedLocales } = useBackendGlobals();
  const { currentLanguage, changeLanguage } = useI18n();
  const screenLoader = useScreenLoader();
  const [subscriptions, setSubscriptions] = React.useState<Record<string, boolean>>({});

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    screenLoader.turnOn();
    onApiSubmit({ subscriptions })
      .then((r) => onSaved(r))
      .catch((e) => showErrorToast(e, { extract: true }))
      .finally(() => {
        setSubscriptions({});
        screenLoader.turnOff();
      });
  }

  return (
    <Page buffer appNav gap={4}>
      <PageHeader back title={t("preferences.title")} subtitle={t("preferences.intro")} />
      <h3>Language</h3>
      <LanguageSwitcher
        supportedLocales={supportedLocales?.items || []}
        currentLanguage={currentLanguage}
        changeLanguage={changeLanguage}
      />
      <h3>Messaging</h3>
      <Form onSubmit={handleSubmit}>
        {user.preferences.subscriptions.map((sub, idx) => {
          const optedIn = has(subscriptions, sub.key)
            ? subscriptions[sub.key]
            : sub.optedIn;
          return (
            <Subscription
              key={sub.key}
              index={idx}
              subscriptionKey={sub.key}
              optedIn={optedIn}
              editableState={sub.editableState}
              onCheckChange={(ch) => setSubscriptions({ [sub.key]: ch })}
            />
          );
        })}
        {children}
        <ButtonGroup col bottom>
          <ContinueButton>{t("forms.save")}</ContinueButton>
          <BackButton />
        </ButtonGroup>
      </Form>
    </Page>
  );
}

interface SubscriptionProps {
  index?: number;
  subscriptionKey: string;
  optedIn: boolean;
  editableState: string;
  onCheckChange: (checked: boolean) => void;
}

function Subscription({
  subscriptionKey,
  optedIn,
  editableState,
  onCheckChange,
}: SubscriptionProps) {
  return (
    <div className="mt-4">
      {editableState === "hidden" ? (
        <p className="mb-0">{t(`preferences.${subscriptionKey}.title`)}</p>
      ) : (
        <Checkbox
          id={subscriptionKey}
          label={t(`preferences.${subscriptionKey}.title`)}
          checked={optedIn}
          disabled={editableState !== "on"}
          help={t(`preferences.${subscriptionKey}.helper_text`)}
          onChange={(e) => onCheckChange(e.target.checked)}
        />
      )}
    </div>
  );
}
