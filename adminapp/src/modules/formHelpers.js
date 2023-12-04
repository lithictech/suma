const initialTranslation = { en: "", es: "" };

const initialFulfillmentOption = { type: "pickup", description: initialTranslation };

const initialFulfillmentAddress = {
  address1: "",
  address2: "",
  city: "",
  stateOrProvince: "",
  postalCode: "",
};

const formHelpers = {
  initialTranslation,
  initialFulfillmentOption,
  initialFulfillmentAddress,
};

export default formHelpers;
