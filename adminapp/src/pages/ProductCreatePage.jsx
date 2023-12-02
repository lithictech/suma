import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import formHelpers from "../modules/formHelpers";
import theme from "../theme";
import ProductForm from "./ProductForm";
import { FormLabel, Stack, TextField, Typography } from "@mui/material";
import merge from "lodash/merge";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function ProductCreatePage() {
  const product = {
    image: null,
    description: formHelpers.initialTranslation,
    name: formHelpers.initialTranslation,
    ourCost: config.defaultZeroMoney,
    vendor: null,
    category: null,
    maxQuantityPerOffering: null,
    maxQuantityPerOrder: null,
    limitedQuantity: false,
    quantityOnHand: 0,
    quantityPendingFulfillment: 0,
  };
  const [changes, setChanges] = React.useState({});
  const resource = merge({}, product, changes);

  const handleApplyChange = () => {
    return api.createCommerceProduct(resource);
  };

  return (
    <ProductForm
      resource={resource}
      setFields={setChanges}
      setField={(f, v) => setChanges({ ...changes, [f]: v })}
      setFieldFromInput={(e) =>
        setChanges({ ...changes, [e.target.name]: e.target.value })
      }
      applyChange={handleApplyChange}
    />
  );
}
