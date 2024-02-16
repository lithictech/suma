import api from "../api";
import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import { dayjsOrNull, formatOrNull } from "../modules/dayConfig";
import formHelpers from "../modules/formHelpers";
import mergeAt from "../shared/mergeAt";
import useMountEffect from "../shared/react/useMountEffect";
import useToggle from "../shared/react/useToggle";
import withoutAt from "../shared/withoutAt";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import RemoveIcon from "@mui/icons-material/Remove";
import {
  Button,
  Divider,
  FormControl,
  FormControlLabel,
  FormLabel,
  Icon,
  InputLabel,
  FormHelperText,
  MenuItem,
  Select,
  Stack,
  Switch,
  TextField,
} from "@mui/material";
import Box from "@mui/material/Box";
import { DateTimePicker } from "@mui/x-date-pickers";
import isEmpty from "lodash/isEmpty";
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
          image={resource.image instanceof Blob && resource.image}
          onImageChange={(f) => setField("image", f)}
          required={isCreate}
        />
        {resource.image?.url && (
          <img src={resource.image.url} alt={resource.image.caption} />
        )}
        <FormLabel>Description (text in offering list)</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("description")}
            label="Description"
            fullWidth
            value={resource.description}
            required
            placeholder="foo"
            onChange={(v) => setField("description", v)}
          />
        </ResponsiveStack>
        <FormLabel>Fulfillment Prompt ("how do you want to get your stuff?")</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("fulfillmentPrompt")}
            label="Fulfillment Prompt"
            fullWidth
            value={resource.fulfillmentPrompt}
            required
            onChange={(v) => setField("fulfillmentPrompt", v)}
          />
        </ResponsiveStack>
        <FormLabel>Fulfillment Confirmation ("how you're getting your stuff")</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("fulfillmentConfirmation")}
            label="Fulfillment Confirmation"
            fullWidth
            value={resource.fulfillmentConfirmation}
            required
            onChange={(v) => setField("fulfillmentConfirmation", v)}
          />
        </ResponsiveStack>
        <FormLabel>Timings</FormLabel>
        <FormHelperText>
          Orders can be placed between the offering begin and end times.
        </FormHelperText>
        <ResponsiveStack alignItems="center" divider={<RemoveIcon />}>
          <DateTimePicker
            label="Open offering *"
            value={dayjsOrNull(resource.periodBegin)}
            closeOnSelect
            onChange={(v) => setField("periodBegin", formatOrNull(v))}
            sx={{ width: "100%" }}
          />
          <DateTimePicker
            label="Close offering *"
            value={dayjsOrNull(resource.periodEnd)}
            onChange={(v) => setField("periodEnd", formatOrNull(v))}
            closeOnSelect
            sx={{ width: "100%" }}
          />
        </ResponsiveStack>
        <DateTimePicker
          label="Begin Fulfillment At"
          value={dayjsOrNull(resource.beginFulfillmentAt)}
          onChange={(v) => setField("beginFulfillmentAt", formatOrNull(v))}
          closeOnSelect
          sx={{ width: { xs: "100%", sm: "50%" } }}
        />
        <FormHelperText>
          Orders can be fulfilled (picked up, etc) after this time. If blank, fulfillment
          is done by admins.
        </FormHelperText>
        <Divider />
        <FormLabel>Other Settings</FormLabel>
        <Stack direction="row" spacing={2}>
          <FormControlLabel
            control={<Switch />}
            label="Prohibit Charge At Checkout"
            name="prohibitChargeAtCheckout"
            checked={resource.prohibitChargeAtCheckout}
            onChange={setFieldFromInput}
          />
        </Stack>
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
    setOptions([...options, initialFulfillmentOption]);
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
  const addingAddress = useToggle(Boolean(address));
  function handleAddressChange(a) {
    onChange({ address: { ...address, ...a } });
  }
  function handleAddressOn() {
    addingAddress.turnOn();
    onChange({ address: initialFulfillmentAddress });
  }
  function handleAddressOff() {
    addingAddress.turnOff();
    onChange({ address: null });
  }
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
        <Stack spacing={2}>
          {addingAddress.isOff ? (
            <Button onClick={handleAddressOn}>
              <AddIcon /> Add Address
            </Button>
          ) : (
            <>
              <OptionAddress address={address} onFieldChange={handleAddressChange} />
              <Button onClick={handleAddressOff} variant="warning">
                <Icon color="warning">
                  <DeleteIcon />
                </Icon>
                Remove Address
              </Button>
            </>
          )}
        </Stack>
      </Stack>
    </Box>
  );
}

function OptionAddress({ address, onFieldChange }) {
  const [supportedGeographies, setSupportedGeographies] = React.useState({});

  useMountEffect(() => {
    api
      .getSupportedGeographies()
      .then(api.pickData)
      .then((data) => {
        setSupportedGeographies(data);
      });
  }, []);

  function handleChange(e) {
    onFieldChange({ [e.target.name]: e.target.value });
  }

  return (
    <Stack spacing={2}>
      <FormLabel>Address</FormLabel>
      <ResponsiveStack>
        <TextField
          value={address.address1}
          name="address1"
          size="small"
          label="Street Address"
          variant="outlined"
          onChange={handleChange}
          fullWidth
          required
        />
        <TextField
          name="address2"
          value={address.address2}
          size="small"
          label="Unit or Apartment Number"
          variant="outlined"
          onChange={handleChange}
          fullWidth
        />
      </ResponsiveStack>
      <ResponsiveStack>
        <TextField
          name="city"
          value={address.city}
          size="small"
          label="City"
          variant="outlined"
          onChange={handleChange}
          required
        />
        <FormControl size="small" sx={{ width: { xs: "100%", sm: "50%" } }} required>
          <InputLabel>State</InputLabel>
          <Select
            label="State"
            name="stateOrProvince"
            value={
              !isEmpty(supportedGeographies?.provinces) ? address.stateOrProvince : ""
            }
            onChange={handleChange}
          >
            <MenuItem disabled>Choose state</MenuItem>
            {supportedGeographies?.provinces?.map((st) => (
              <MenuItem key={st.value} value={st.value}>
                {st.label}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
        <TextField
          name="postalCode"
          value={address.postalCode}
          size="small"
          label="Zip code"
          variant="outlined"
          onChange={handleChange}
          required
        />
      </ResponsiveStack>
    </Stack>
  );
}

const { initialFulfillmentAddress, initialFulfillmentOption } = formHelpers;
