import api from "../api";
import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
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
  MenuItem,
  Select,
  Stack,
  Switch,
  TextField,
  Typography,
} from "@mui/material";
import Box from "@mui/material/Box";
import { DateTimePicker } from "@mui/x-date-pickers";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function OfferingCreatePage() {
  const navigate = useNavigate();
  const [image, setImage] = React.useState(null);
  const [description, setDescription] = React.useState(initialTranslation);
  const [fulfillmentPrompt, setFulfillmentPrompt] = React.useState(initialTranslation);
  const [fulfillmentConfirmation, setFulfillmentConfirmation] =
    React.useState(initialTranslation);
  const [fulfillmentOptions, setFulfillmentOptions] = React.useState([
    initialFulfillmentOption,
  ]);
  const [opensAt, setOpensAt] = React.useState(dayjs());
  const [closesAt, setClosesAt] = React.useState(dayjs().add(1, "day"));
  const [beginFulfillmentAt, setBeginFulfillmentAt] = React.useState(dayjs());
  const [prohibitChargeAtCheckout, setProhibitChargeAtCheckout] = React.useState(false);
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  const submit = () => {
    busy();
    api
      .createCommerceOffering({
        image,
        description,
        fulfillmentPrompt,
        fulfillmentConfirmation,
        fulfillmentOptions,
        opensAt: opensAt?.format(),
        closesAt: closesAt?.format(),
        beginFulfillmentAt: beginFulfillmentAt?.format(),
        prohibitChargeAtCheckout,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  };
  return (
    <FormLayout
      title="Create a Offering"
      subtitle="Offerings holds products that can be ordered at checkout. They are only available
        during their period. Add eligibility constraints in the details page after creating it."
      onSubmit={handleSubmit(submit)}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ImageFileInput image={image} onImageChange={(f) => setImage(f)} />
        <FormLabel>Description:</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("description")}
            label="Description"
            fullWidth
            value={description}
            required
            onChange={(description) => setDescription(description)}
          />
        </ResponsiveStack>
        <FormLabel>Fulfillment Prompt (for checkout):</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("fulfillmentPrompt")}
            label="Fulfillment Prompt"
            fullWidth
            value={fulfillmentPrompt}
            required
            onChange={(fulfillmentPrompt) => setFulfillmentPrompt(fulfillmentPrompt)}
          />
        </ResponsiveStack>
        <FormLabel>Fulfillment Confirmation (for checkout):</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("fulfillmentConfirmation")}
            label="Fulfillment Confirmation"
            fullWidth
            value={fulfillmentConfirmation}
            required
            onChange={(fulfillmentConfirmation) =>
              setFulfillmentConfirmation(fulfillmentConfirmation)
            }
          />
        </ResponsiveStack>
        <FulfillmentOptions
          options={fulfillmentOptions}
          setOptions={setFulfillmentOptions}
        />
        <FormLabel>Period:</FormLabel>
        <ResponsiveStack alignItems="center" divider={<RemoveIcon />}>
          <DateTimePicker
            label="Beginning date *"
            value={opensAt}
            closeOnSelect
            onChange={(date) => setOpensAt(date)}
            sx={{ width: "100%" }}
          />
          <DateTimePicker
            label="Ending date *"
            value={closesAt}
            onChange={(date) => setClosesAt(date)}
            closeOnSelect
            sx={{ width: "100%" }}
          />
        </ResponsiveStack>
        <Divider />
        <Typography variant="h6">Optional</Typography>
        <FormLabel>Begin Fulfillment Date (of orders):</FormLabel>
        <DateTimePicker
          label="Begin At"
          value={beginFulfillmentAt}
          onChange={(date) => setBeginFulfillmentAt(date)}
          closeOnSelect
          sx={{ width: { xs: "100%", sm: "50%" } }}
        />
        <Stack direction="row" spacing={2}>
          <FormControlLabel
            control={<Switch />}
            label="Prohibit Charge At Checkout"
            checked={prohibitChargeAtCheckout}
            onChange={() => setProhibitChargeAtCheckout(!prohibitChargeAtCheckout)}
          />
        </Stack>
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

function FulfillmentOption({ type, description, address, onChange, onRemove }) {
  const addingAddress = useToggle(false);
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
        <Typography variant="h6">Fulfillment Option</Typography>
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
        <FormLabel>Description:</FormLabel>
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
      <FormLabel>Address:</FormLabel>
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
            value={address.stateOrProvince}
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

const { initialTranslation, initialFulfillmentAddress, initialFulfillmentOption } =
  formHelpers;
