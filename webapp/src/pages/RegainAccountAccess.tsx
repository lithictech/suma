import TODO from "../components/TODO.tsx";

export default function RegainAccountAccess({ success }: { success?: boolean }) {
  return <TODO>{success}</TODO>;
}
// export default function RegainAccountAccess({ success }: { success?: boolean }) {
//   const navigate = useNavigate();
//   const submitting = useToggle(false);
//   const [error, setError] = useError();
//   const [state, setState] = React.useState({ name: "" });
//
//   const {
//     register,
//     handleSubmit,
//     clearErrors,
//     setValue,
//     control,
//     formState: { errors },
//   } = useForm<{previousPhone: string, currentPhone: string}>({
//     mode: "all",
//   });
//
//   function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
//     clearErrors();
//     setValue(e.target.name, e.target.value);
//     setState({ ...state, [e.target.name]: e.target.value });
//   }
//
//   function handleSubmitForm(data: { previousPhone: string; currentPhone: string }) {
//     submitting.turnOn();
//     setError(null);
//     api
//       .supportRegainAccountAccess({ ...state, ...data })
//       .then(() => navigate("/regain-account-access/success", { replace: true }))
//       .catch((err: any) => {
//         setError(extractLocalizedError(err));
//         submitting.turnOff();
//       });
//   }
//   if (success) {
//     return (
//       <div className="d-flex flex-column">
//         <h2>{t("common.thank_you")}</h2>
//         <p>{t("auth.access_account_confirmed")}</p>
//         <Button
//           variant="outline"
//           to="/"
//           className="w-100 align-self-center"
//           style={{ maxWidth: 330 }}
//         >
//           {t("common.return_home")}
//         </Button>
//       </div>
//     );
//   }
//   return (
//     <>
//       <h2>{t("auth.access_account_title")}</h2>
//       <p>{t("auth.access_account_subtitle")}</p>
//       <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
//         <PhoneInput
//           className="mb-3"
//           name="previousPhone"
//           control={control}
//           clearErrors={clearErrors}
//           label={t("auth.access_account_previous_phone")}
//           autoFocus
//           required
//           disabled={submitting.isOn}
//         />
//         <PhoneInput
//           className="mb-3"
//           name="currentPhone"
//           control={control}
//           clearErrors={clearErrors}
//           label={t("auth.access_account_current_phone")}
//           required
//           disabled={submitting.isOn}
//         />
//         <FormControlGroup
//           className="mb-3"
//           name="name"
//           autoComplete="name"
//           label={t("forms.name")}
//           required
//           register={register}
//           errors={errors}
//           value={state.name}
//           disabled={submitting.isOn}
//           onChange={handleChange}
//         />
//         <FormError error={error} />
//         <TODO>
//           {`<FormButtons
//           back
//           primaryProps={{
//             children: t("forms.submit"),
//             disabled: submitting.isOn,
//           }}
//         />`}
//         </TODO>
//       </Form>
//     </>
//   );
// }
