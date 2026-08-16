import { t } from "../localization";
import CardText from "../ui/CardText.tsx";
import CheckboxCard from "../ui/CheckboxCard.tsx";
import "./SignupAgreement.css";
import React from "react";
import { useController, Control } from "react-hook-form";

interface SignupAgreementProps {
  control: Control<{ phone: string; agree: boolean }>;
  error?: React.ReactNode;
}

export default function SignupAgreement({ control, error }: SignupAgreementProps) {
  const {
    field: { value: agree, onChange: onAgreeChange, ref: agreeRef },
  } = useController({
    name: "agree",
    control,
    rules: { required: t("common.agree_to_continue") },
    defaultValue: false,
  });
  // const inputRef = React.useRef<HTMLInputElement>(null);

  // const { ref: rhfRef, ...registerRest } = register("agree", {
  //   validate: (value: boolean) => value === true || ,
  // });

  // function handleDivClick(e: React.MouseEvent) {
  // avoid double-toggling if the user clicked the input/label directly
  // if (e.target === inputRef.current) {
  //   return;
  // }
  // inputRef.current?.click();
  // }

  // aria-label={t("auth.agree_aria_label")}

  return (
    <CheckboxCard
      ref={agreeRef}
      checked={!!agree}
      onChange={onAgreeChange}
      error={error}
      required
      alignCheckbox="start"
    >
      <CardText>
        {t("auth.sign_up_agreement", { buttonLabel: t("forms.continue") })}
      </CardText>
    </CheckboxCard>
  );
}
