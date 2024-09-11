import AddressInputs from "../components/AddressInputs";
import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import { formatOrNull } from "../modules/dayConfig";
import formHelpers from "../modules/formHelpers";
import mergeAt from "../shared/mergeAt";
import withoutAt from "../shared/withoutAt";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import RemoveIcon from "@mui/icons-material/Remove";
import {
  Button,
  Divider,
  FormControl,
  FormLabel,
  Icon,
  InputLabel,
  FormHelperText,
  MenuItem,
  Select,
  Stack,
  TextField,
} from "@mui/material";
import Box from "@mui/material/Box";
import React from "react";

export default function OfferingForm({
  isCreate,
  resource,
  setField,
  setFieldFromInput,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create an Offering" : "Update Offering"}
      subtitle="Offerings holds products that can be ordered at checkout. They are only available
        for a defined time. Add eligibility constraints in the details page after creating it."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ImageFileInput
          image={resource.image}
          onImageChange={(f) => setField("image", f)}
          required={isCreate}
        />
        <FormLabel>Description (text in offering list)</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("description")}
            label="Description"
            fullWidth
            value={resource.description}
            required
            onChange={(v) => setField("description", v)}
          />
        </ResponsiveStack>
        <FormLabel>Timings</FormLabel>
        <FormHelperText>
          Orders can be placed between the offering begin and end times.
        </FormHelperText>
        <ResponsiveStack alignItems="center" divider={<RemoveIcon />}>
          <SafeDateTimePicker
            label="Open offering *"
            value={resource.periodBegin}
            onChange={(v) => setField("periodBegin", formatOrNull(v))}
          />
          <SafeDateTimePicker
            label="Close offering *"
            value={resource.periodEnd}
            onChange={(v) => setField("periodEnd", formatOrNull(v))}
          />
        </ResponsiveStack>
        <SafeDateTimePicker
          label="Begin Fulfillment At"
          value={resource.beginFulfillmentAt}
          onChange={(v) => setField("beginFulfillmentAt", formatOrNull(v))}
          sx={{ width: { xs: "100%", sm: "50%" } }}
        />
        <FormHelperText>
          Orders can be fulfilled (picked up, etc) after this time. If blank, fulfillment
          is done by admins.
        </FormHelperText>
        <Divider />
        <FormLabel>Other Settings</FormLabel>
        <ResponsiveStack>
          <TextField
            name="maxOrderedItemsCumulative"
            value={resource.maxOrderedItemsCumulative || ""}
            type="number"
            label="Max ordered items, cumulative"
            helperText="The maximum number of products total can be sold in this offering. Empty if unenforced."
            onChange={setFieldFromInput}
          />
          <TextField
            name="maxOrderedItemsPerMember"
            value={resource.maxOrderedItemsPerMember || ""}
            type="number"
            label="Max ordered items, per-member"
            helperText="The maximum number of products a given member can purchase in this offering. Empty if unenforced."
            onChange={setFieldFromInput}
          />
        </ResponsiveStack>
        <Divider />
        <FormLabel>Fulfillment Prompt ("how do you want to get your stuff?")</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("fulfillmentPrompt")}
            label="Fulfillment Prompt"
            fullWidth
            value={resource.fulfillmentPrompt}
            onChange={(v) => setField("fulfillmentPrompt", v)}
          />
        </ResponsiveStack>
        <FormLabel>
          Fulfillment Instructions ("pickup your vouchers with suma staff at...")
        </FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("fulfillmentInstructions")}
            label="Fulfillment Instructions"
            fullWidth
            value={resource.fulfillmentInstructions}
            onChange={(v) => setField("fulfillmentInstructions", v)}
          />
        </ResponsiveStack>
        <FormLabel>Fulfillment Confirmation ("how you're getting your stuff")</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("fulfillmentConfirmation")}
            label="Fulfillment Confirmation"
            fullWidth
            value={resource.fulfillmentConfirmation}
            onChange={(v) => setField("fulfillmentConfirmation", v)}
          />
        </ResponsiveStack>
        <FormLabel>Fulfillment Options</FormLabel>
        <FulfillmentOptions
          options={resource.fulfillmentOptions}
          setOptions={(v) => setField("fulfillmentOptions", v)}
        />
      </Stack>
    </FormLayout>
  );
}

function FulfillmentOptions({ options, setOptions }) {
  const handleAdd = () => {
    setOptions([...options, formHelpers.initialFulfillmentOption]);
  };
  const handleRemove = (index) => {
    setOptions(withoutAt(options, index));
  };
  function handleChange(index, fields) {
    setOptions(mergeAt(options, index, fields));
  }
  return (
    <>
      {options.map((o, i) => (
        <FulfillmentOption
          key={i}
          {...o}
          index={i}
          onChange={(fields) => handleChange(i, fields)}
          onRemove={() => handleRemove(i)}
        />
      ))}
      <Button onClick={handleAdd}>
        <AddIcon /> Add Fulfillment option
      </Button>
    </>
  );
}

function FulfillmentOption({ index, type, description, address, onChange, onRemove }) {
  return (
    <Box sx={{ p: 2, border: "1px dashed grey" }}>
      <Stack
        direction="row"
        spacing={2}
        mb={2}
        sx={{ justifyContent: "space-between", alignItems: "center" }}
      >
        <FormLabel>Option {index}</FormLabel>
        <Button onClick={(e) => onRemove(e)} variant="warning" sx={{ marginLeft: "5px" }}>
          <Icon color="warning">
            <DeleteIcon />
          </Icon>
          Remove
        </Button>
      </Stack>
      <Stack spacing={2}>
        <FormControl required>
          <InputLabel>Type</InputLabel>
          <Select
            label="Type"
            value={type}
            onChange={(e) => onChange({ type: e.target.value })}
          >
            <MenuItem value="pickup">Pickup</MenuItem>
            <MenuItem value="delivery">Delivery</MenuItem>
          </Select>
        </FormControl>
        <FormLabel>Description</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            label="Description"
            fullWidth
            value={description}
            required
            onChange={(v) => onChange({ description: v })}
          />
        </ResponsiveStack>
        <AddressInputs
          address={address}
          onFieldChange={(addressObj) => onChange(addressObj)}
        />
      </Stack>
    </Box>
  );
}
