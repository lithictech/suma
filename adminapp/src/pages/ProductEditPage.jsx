import api from "../api";
import FormLayout from "../components/FormLayout";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import ProductForm from "./ProductForm";
import merge from "lodash/merge";
import React from "react";
import { useParams } from "react-router-dom";

export default function ProductEditPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { id } = useParams();

  const getCommerceProduct = React.useCallback(() => {
    return api.getCommerceProduct({ id: Number(id) }).catch(enqueueErrorSnackbar);
  }, [enqueueErrorSnackbar, id]);
  const {
    state: product,
    loading: productLoading,
    error: productError,
  } = useAsyncFetch(getCommerceProduct, {
    default: {},
    pickData: true,
  });
  const [changes, setChanges] = React.useState({});
  if (productLoading || productError) {
    return <FormLayout isBusy />;
  }
  const handleApplyChange = () => {
    return api.updateCommerceProduct({ id: product.id, ...changes });
  };
  const resource = merge({}, product, changes);
  return (
    <ProductForm
      resource={resource}
      setFields={setChanges}
      setField={(f, v) => setChanges({ [f]: v })}
      setFieldFromInput={(e) => setChanges({ [e.target.name]: e.target.value })}
      applyChange={handleApplyChange}
    />
  );
}
