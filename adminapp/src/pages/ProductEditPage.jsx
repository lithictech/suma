import api from "../api";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import VendorSelect from "../components/VendorSelect";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import formHelpers from "../modules/formHelpers";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import theme from "../theme";
import { FormLabel, Stack, TextField, Typography } from "@mui/material";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useParams } from "react-router-dom";

export default function ProductEditPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const navigate = useNavigate();
  const [image, setImage] = React.useState(null);
  const [description, setDescription] = React.useState(formHelpers.initialTranslation);
  const [name, setName] = React.useState(formHelpers.initialTranslation);
  const [ourCost, setOurCost] = React.useState(config.defaultZeroMoney);
  const [vendor, setVendor] = React.useState(null);
  const [category, setCategory] = React.useState(null);
  const [maxQuantityPerOffering, setMaxQuantityPerOffering] = React.useState(1);
  const [maxQuantityPerOrder, setMaxQuantityPerOrder] = React.useState(1);
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  const getCommerceProduct = React.useCallback(() => {
    return api.getCommerceProduct({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: product, loading: productLoading } = useAsyncFetch(getCommerceProduct, {
    default: {},
    pickData: true,
  });

  React.useEffect(() => {
    if (productLoading) {
      return;
    }
    setImage(product.image);
    setName(product.name);
    setDescription(product.description);
    setOurCost(product.ourCost);
    setVendor(product.vendor);
    setCategory(product.vendorServiceCategory);
    setMaxQuantityPerOffering(product.maxQuantityPerOffering);
    setMaxQuantityPerOrder(product.maxQuantityPerOrder);
  }, [productLoading, product]);
  const submit = () => {
    busy();
    // TODO: Pass image as Blob or File
    api
      .updateCommerceProduct({
        id,
        name,
        description,
        ourCost,
        vendorName: vendor?.name,
        vendorServiceCategorySlug: category?.slug,
        maxQuantityPerOrder: maxQuantityPerOrder,
        maxQuantityPerOffering: maxQuantityPerOffering,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  };
  return (
    <FormLayout
      title={`Edit Product ${id}`}
      subtitle="A product is abstract, it can represent different goods. It is tied to a Vendor
        and can later be listed with an Offering, a.k.a OfferingProduct. If the Offering
        and Product are available on the platform, product will appear in the Food list
        and details page. Discount price can be set when creating an OfferingProduct."
      onSubmit={handleSubmit(submit)}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ImageFileInput
          image={image instanceof Blob && image}
          onImageChange={(f) => setImage(f)}
        />
        {image?.url && <img src={image.url} alt={image.caption} />}
        <Stack spacing={2}>
          <FormLabel>Name:</FormLabel>
          <ResponsiveStack>
            <MultiLingualText
              {...register("name")}
              label="Name"
              fullWidth
              value={name}
              required
              onChange={(name) => setName(name)}
            />
          </ResponsiveStack>
        </Stack>
        <FormLabel>Description:</FormLabel>
        <Stack spacing={2}>
          <MultiLingualText
            {...register("description")}
            label="Description"
            fullWidth
            value={description}
            required
            onChange={(description) => setDescription(description)}
          />
        </Stack>
        <ResponsiveStack sx={{ pt: theme.spacing(2) }}>
          <CurrencyTextField
            // TODO: Ensure money is rendered
            {...register("ourCost")}
            label="Our Cost"
            helperText="How much does suma offer this product for?"
            money={ourCost}
            required
            style={{ flex: 1 }}
            onMoneyChange={setOurCost}
          />
          <VendorSelect
            {...register("vendor")}
            label="Vendor"
            helperText="What vendor offers this product?"
            value={vendor?.name || ""}
            title={vendor?.name}
            style={{ flex: 1 }}
            onChange={(_, vendorObj) => setVendor(vendorObj)}
          />
          <VendorServiceCategorySelect
            {...register("category")}
            label="Category"
            helperText="What can this be used for?"
            value={category?.slug || ""}
            title={category?.label}
            style={{ flex: 1 }}
            onChange={(_, categoryObj) => setCategory(categoryObj)}
            required
          />
        </ResponsiveStack>
        <Typography variant="h6">Inventory</Typography>
        <ResponsiveStack>
          <TextField
            type="number"
            label="Max Quantity Per Offering"
            helperText="The maximum allowed for this offering per member"
            fullWidth
            value={maxQuantityPerOffering}
            onChange={(e) => setMaxQuantityPerOffering(e.target.value)}
            required
          />
          <TextField
            type="number"
            label="Max Quantity Per Order"
            helperText="The maximum allowed for each member's order"
            fullWidth
            value={maxQuantityPerOrder}
            onChange={(e) => setMaxQuantityPerOrder(e.target.value)}
            required
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
