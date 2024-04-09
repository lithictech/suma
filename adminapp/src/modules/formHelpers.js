const initialTranslation = { en: "", es: "" };

const initialFulfillmentOption = { type: "pickup", description: initialTranslation };

const initialAddress = {
  address1: "",
  address2: "",
  city: "",
  stateOrProvince: "",
  postalCode: "",
};

const formHelpers = {
  initialTranslation,
  initialFulfillmentOption,
  initialAddress,
};

export default formHelpers;
