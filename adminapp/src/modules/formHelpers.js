const initialTranslation = { en: "", es: "" };

const initialFulfillmentOption = { type: "pickup", description: initialTranslation };

const initialFulfillmentAddress = {
  address1: "",
  address2: "",
  city: "",
  stateOrProvince: "",
  postalCode: "",
};
const responsiveStackDirection = { xs: "column", sm: "row" };

const formHelpers = {
  initialTranslation,
  initialFulfillmentOption,
  initialFulfillmentAddress,
  responsiveStackDirection,
};

export default formHelpers;
