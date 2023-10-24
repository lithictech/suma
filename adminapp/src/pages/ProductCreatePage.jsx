import api from "../api";
import CurrencyTextField from "../components/CurrencyTextField";
import FormButtons from "../components/FormButtons";
import ImageFileInput from "../components/ImageFileInput";
import MultiLingualText from "../components/MultiLingualText";
import VendorSelect from "../components/VendorSelect";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import theme from "../theme";
import { FormLabel, Stack, TextField, Typography } from "@mui/material";
import Box from "@mui/material/Box";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function ProductCreatePage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [image, setImage] = React.useState(null);
  const [description, setDescription] = React.useState(newTranslation);
  const [name, setName] = React.useState(newTranslation);
  const [ourCost, setOurCost] = React.useState(config.defaultZeroMoney);
  const [vendor, setVendor] = React.useState(null);
  const [category, setCategory] = React.useState(null);
  const maxQuantityPerOffering = React.useRef(1);
  const maxQuantityPerOrder = React.useRef(1);
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  const submit = () => {
    busy();
    api
      .createCommerceProduct({
        image,
        name,
        description,
        ourCost,
        vendorName: vendor?.name,
        vendorServiceCategorySlug: category?.slug,
        maxQuantityPerOrder: maxQuantityPerOrder.current.value,
        maxQuantityPerOffering: maxQuantityPerOffering.current.value,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  };
  return (
    <div style={{ maxWidth: 650 }}>
      <Typography variant="h4" gutterBottom>
        Create a Product
      </Typography>
      <Typography variant="body1" gutterBottom>
        A product is abstract, it can represent different goods. It is tied to a Vendor
        and can later be listed with an Offering, a.k.a OfferingProduct. If the Offering
        and Product are available, product will appear in the Offering list and details
        page.
      </Typography>
      <Box component="form" mt={2} onSubmit={handleSubmit(submit)}>
        <ImageFileInput image={image} onImageChange={(f) => setImage(f)} />
        <Stack spacing={2} direction="column">
          <Stack spacing={2} direction="column">
            <FormLabel>Name:</FormLabel>
            <Stack direction={responsiveStackDirection} spacing={2}>
              <MultiLingualText
                {...register("name")}
                label="Name"
                fullWidth
                value={name}
                required
                onChange={(name) => setName(name)}
              />
            </Stack>
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
          <Stack
            direction={responsiveStackDirection}
            spacing={2}
            sx={{ pt: theme.spacing(2) }}
          >
            <CurrencyTextField
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
              defaultValue={searchParams.get("vendorName")}
              label="Vendor"
              helperText="What vendor offers this product?"
              value={vendor?.name || ""}
              disabled={Boolean(searchParams.get("vendorServiceCategorySlug"))}
              title={vendor?.name}
              style={{ flex: 1 }}
              onChange={(_, vendorObj) => setVendor(vendorObj)}
            />
            <VendorServiceCategorySelect
              {...register("category")}
              defaultValue={searchParams.get("vendorServiceCategorySlug")}
              label="Category"
              helperText="What can this be used for?"
              value={category?.slug || ""}
              disabled={Boolean(searchParams.get("vendorServiceCategorySlug"))}
              title={category?.label}
              style={{ flex: 1 }}
              onChange={(_, categoryObj) => setCategory(categoryObj)}
              required
            />
          </Stack>
          <Typography variant="h6">Inventory</Typography>
          <Stack direction={responsiveStackDirection} spacing={2}>
            <TextField
              inputRef={maxQuantityPerOffering}
              type="number"
              label="Max Quantity Per Offering"
              helperText="The maximum allowed for this offering per member"
              fullWidth
              required
            />
            <TextField
              inputRef={maxQuantityPerOrder}
              type="number"
              label="Max Quantity Per Order"
              helperText="The maximum allowed for each member's order"
              fullWidth
              required
            />
          </Stack>
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}

const newTranslation = { en: "", es: "" };

const responsiveStackDirection = { xs: "column", sm: "row" };
