import api from "../api";
import AddCreditCard from "../components/AddCreditCard";
import GoHome from "../components/GoHome";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import { md, mdp, t } from "../localization";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import React from "react";

export default function FundingAddCard() {
  const [submitSuccessful, setSubmitSuccessful] = React.useState(false);
  const { user, setUser, handleUpdateCurrentMember } = useUser();
  const screenLoader = useScreenLoader();
  const [error, setError] = useError();

  function handleCardSuccess(stripeToken) {
    screenLoader.turnOn();
    setError("");
    api
      .createCardStripe({ token: stripeToken })
      .tap(handleUpdateCurrentMember)
      .then((r) => {
        setUser({ ...user, usablePaymentInstruments: r.data.allPaymentInstruments });
        setSubmitSuccessful(true);
      })
      .catch((e) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  }
  return (
    <>
      {submitSuccessful ? (
        <Success />
      ) : (
        <>
          <LinearBreadcrumbs back />
          <h2 className="page-header">{t("payments:add_card")}</h2>
          <p>{md("payments:payment_intro.privacy_statement_md")}</p>
          <AddCreditCard
            error={error}
            setError={setError}
            onSuccess={handleCardSuccess}
          />
        </>
      )}
    </>
  );
}

function Success() {
  return (
    <>
      <h2>{t("payments:added_card")}</h2>
      {mdp("payments:added_card_successful_md")}
      <GoHome />
    </>
  );
}

// function AddCard({ onSuccess }) {
//   const {
//     register,
//     handleSubmit,
//     clearErrors,
//     setValue,
//     formState: { errors },
//   } = useForm({
//     mode: "all",
//   });
//   const [error, setError] = useError();
//
//   const numberRowRef = React.useRef(null);
//   const expiryRowRef = React.useRef(null);
//   const errorRowRef = React.useRef(null);
//   const buttonRowRef = React.useRef(null);
//   const cardRowRef = React.useRef(null);
//   const [rerender, setRerender] = React.useState(1);
//
//   const [name, setName] = React.useState("");
//   const [number, setNumber] = React.useState("");
//   const [expiry, setExpiry] = React.useState("");
//   const [cvc, setCvc] = React.useState("");
//   const [focus, setFocus] = React.useState("");
//
//   const runSetter = (name, set, value) => {
//     clearErrors(name);
//     setValue(name, value);
//     set(value);
//   };
//
//   const handleFocus = (e) => {
//     setFocus(e.target.name);
//     setTimeout(() => setRerender(rerender + 1), 0);
//   };
//   const handleBlur = () => setFocus("");
//
//   let numberOffset = 0,
//     expOffset = 0,
//     errorOffset = 0,
//     buttonsOffset = 0,
//     cardOffset = 0;
//   if (focus) {
//     const numberDims = elementDimensions(numberRowRef.current);
//     const expiryDims = elementDimensions(expiryRowRef.current);
//     const errorDims = elementDimensions(errorRowRef.current);
//     const buttonDims = elementDimensions(buttonRowRef.current);
//     const cardDims = elementDimensions(cardRowRef.current);
//     if (focus === "name") {
//       numberOffset = cardDims.h;
//       expOffset = cardDims.h;
//       errorOffset = cardDims.h;
//       buttonsOffset = cardDims.h;
//       cardOffset =
//         -buttonDims.h - errorDims.h - expiryDims.h - numberDims.h + cardDims.my;
//     } else if (focus === "number") {
//       expOffset = cardDims.h;
//       errorOffset = cardDims.h;
//       buttonsOffset = cardDims.h;
//       cardOffset = -buttonDims.h - errorDims.h - expiryDims.h + cardDims.my;
//     } else if (focus === "expiry" || focus === "cvc") {
//       errorOffset = cardDims.h;
//       buttonsOffset = cardDims.h;
//       cardOffset = -buttonDims.h - errorDims.h + cardDims.my;
//     }
//     console.log(numberDims.h, expiryDims.h, errorDims.h, buttonDims.h, cardDims.h);
//   }
//
//   return (
//     <>
//       <LinearBreadcrumbs back />
//       <h2 className="page-header">{t("payments:add_card")}</h2>
//       <p>{md("payments:payment_intro.privacy_statement_md")}</p>
//       <Form noValidate onSubmit={handleSubmit(handleFormSubmit)}>
//         <Row className="mb-3">
//           <FormControlGroup
//             as={Col}
//             required
//             type="text"
//             name="name"
//             autoComplete="name"
//             autoCorrect="off"
//             spellCheck="false"
//             label={t("forms:name")}
//             value={name}
//             errors={errors}
//             register={register}
//             onChange={(e) => runSetter(e.target.name, setName, e.target.value)}
//             onFocus={handleFocus}
//             onBlur={handleBlur}
//           />
//         </Row>
//         <Row
//           ref={numberRowRef}
//           className="mb-3 cc-animate"
//           style={{ transform: `translateY(${numberOffset}px)` }}
//         >
//           <FormControlGroup
//             as={Col}
//             required
//             type="text"
//             pattern="^[0-9]+$"
//             inputMode="numeric"
//             name="number"
//             autoComplete="cc-number"
//             autoCorrect="off"
//             spellCheck="false"
//             label={t("forms:card_number")}
//             value={number}
//             errors={errors}
//             errorKeys={{ pattern: "forms:invalid_card_number" }}
//             register={register}
//             onChange={(e) =>
//               runSetter(e.target.name, setNumber, keepDigits(e.target.value))
//             }
//             onFocus={handleFocus}
//             onBlur={handleBlur}
//           />
//         </Row>
//         <Row
//           ref={expiryRowRef}
//           className="mb-3 cc-animate"
//           style={{ transform: `translateY(${expOffset}px)` }}
//         >
//           <FormControlGroup
//             as={Col}
//             required
//             type="text"
//             pattern="^[0-9]+$"
//             inputMode="numeric"
//             name="expiry"
//             autoComplete="cc-exp"
//             autoCorrect="off"
//             spellCheck="false"
//             label={"MM / YY"}
//             value={expiry}
//             errors={errors}
//             register={register}
//             onChange={(e) =>
//               runSetter(e.target.name, setExpiry, keepDigits(e.target.value))
//             }
//             onFocus={handleFocus}
//             onBlur={handleBlur}
//           />
//           <FormControlGroup
//             as={Col}
//             required
//             type="text"
//             pattern="^[0-9]{3,4}$"
//             inputMode="numeric"
//             name="cvc"
//             autoComplete="cc-cvc"
//             autoCorrect="off"
//             spellCheck="false"
//             label={"CVC"}
//             value={cvc}
//             errors={errors}
//             register={register}
//             onChange={(e) => runSetter(e.target.name, setCvc, keepDigits(e.target.value))}
//             onFocus={handleFocus}
//             onBlur={handleBlur}
//           />
//         </Row>
//         <FormError
//           ref={errorRowRef}
//           error={error}
//           className="cc-animate"
//           style={{ transform: `translateY(${errorOffset}px)` }}
//         />
//         <FormButtons
//           ref={buttonRowRef}
//           className="mb-3 cc-animate"
//           style={{ transform: `translateY(${buttonsOffset}px)` }}
//           variant="outline-primary"
//           back
//           primaryProps={{
//             children: t("forms:continue"),
//           }}
//         />
//         <Row
//           ref={cardRowRef}
//           className="mb-3 cc-animate"
//           style={{ transform: `translateY(${cardOffset}px)` }}
//         >
//           <Col>
//             <ReactCreditCards
//               cvc={cvc}
//               expiry={expiry}
//               focused={focus}
//               name={name}
//               number={number}
//             />
//           </Col>
//         </Row>
//       </Form>
//       {/*<form*/}
//       {/*  name="helcimForm"*/}
//       {/*  id="helcimForm"*/}
//       {/*  action="your-checkout-page.php"*/}
//       {/*  method="POST"*/}
//       {/*>*/}
//       {/*  <div id="helcimResults"></div>*/}
//       {/*  <input type="hidden" id="token" value="58ae1d44d7ac6959332969" />*/}
//       {/*  <input type="hidden" id="language" value="en" />*/}
//       {/*  Card Token: <input type="text" id="cardToken" />*/}
//       {/*  <br />*/}
//       {/*  Credit Card Number: <input type="text" id="cardNumber" />*/}
//       {/*  <br />*/}
//       {/*  Expiry Month: <input type="text" id="cardExpiryMonth" />*/}
//       {/*  <br />*/}
//       {/*  Expiry Year: <input type="text" id="cardExpiryYear" />*/}
//       {/*  <br />*/}
//       {/*  CVV: <input type="text" id="cardCVV" />*/}
//       {/*  <br />*/}
//       {/*  Card Holder Name: <input type="text" id="cardHolderName" />*/}
//       {/*  <br />*/}
//       {/*  Card Holder Address: <input type="text" id="cardHolderAddress" />*/}
//       {/*  <br />*/}
//       {/*  Card Holder Postal Code: <input type="text" id="cardHolderPostalCode" />*/}
//       {/*  <br />*/}
//       {/*  <input*/}
//       {/*    type="button"*/}
//       {/*    id="buttonProcess"*/}
//       {/*    value="Process"*/}
//       {/*    onClick={() => window.helcimProcess()}*/}
//       {/*  />*/}
//       {/*</form>*/}
//     </>
//   );
// }
