import api from "../api";
import FormButtons from "../components/FormButtons";
import MultiLingualText from "../components/MultiLingualText";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useMountEffect from "../shared/react/useMountEffect";
import useToggle from "../shared/react/useToggle";
import RemoveIcon from "@mui/icons-material/Remove";
import {
  Button,
  Divider,
  FormControl,
  FormControlLabel,
  FormLabel,
  MenuItem,
  Select,
  Stack,
  Switch,
  TextField,
  Typography,
} from "@mui/material";
import Box from "@mui/material/Box";
import { DateTimePicker } from "@mui/x-date-pickers";
import { last } from "lodash";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function OfferingCreatePage() {
  // TODO: Add ability to add images
  const navigate = useNavigate();
  const [description, setDescription] = React.useState(translationObj);
  const [fulfillmentPrompt, setFulfillmentPrompt] = React.useState(translationObj);
  const [fulfillmentConfirmation, setFulfillmentConfirmation] =
    React.useState(translationObj);
  const [fulfillmentOptions, setFulfillmentOptions] = React.useState([]);
  const [periodBegin, setPeriodBegin] = React.useState(null);
  const [periodEnd, setPeriodEnd] = React.useState(null);
  const [beginFulfillmentAt, setBeginFulfillmentAt] = React.useState(null);
  const [prohibitChargeAtCheckout, setProhibitChargeAtCheckout] = React.useState(false);
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  function submit() {
    busy();
    api
      .createCommerceOffering({
        description,
        fulfillmentPrompt,
        fulfillmentConfirmation,
        periodBegin: periodBegin.format(),
        periodEnd: periodEnd.format(),
        beginFulfillmentAt: beginFulfillmentAt && beginFulfillmentAt.format(),
        prohibitChargeAtCheckout,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  }
  return (
    <div style={{ maxWidth: 650 }}>
      <Typography variant="h4" gutterBottom>
        Create an Offering
      </Typography>
      <Typography variant="body1" gutterBottom>
        Offerings holds products that can be ordered at checkout. They are only available
        during their period.
      </Typography>
      <Box component="form" mt={2} onSubmit={handleSubmit(submit)}>
        <Stack spacing={2} direction="column">
          <FormLabel>Description:</FormLabel>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <MultiLingualText
              {...register("description")}
              label="Description"
              fullWidth
              value={description}
              required
              onChange={(description) => setDescription(description)}
            />
          </Stack>
          <FormLabel>Fulfillment Prompt (for checkout):</FormLabel>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <MultiLingualText
              {...register("fulfillmentPrompt")}
              label="Fulfillment Prompt"
              fullWidth
              value={fulfillmentPrompt}
              required
              onChange={(fulfillmentPrompt) => setFulfillmentPrompt(fulfillmentPrompt)}
            />
          </Stack>
          <FormLabel>Fulfillment Confirmation (for checkout):</FormLabel>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
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
          </Stack>
          <AddFulfillmentOption />
          <FormLabel>Period:</FormLabel>
          <Stack
            direction={{ xs: "column", sm: "row" }}
            alignItems="center"
            spacing={2}
            divider={<RemoveIcon />}
          >
            <DateTimePicker
              label="Beginning date *"
              value={periodBegin}
              onChange={(date) => setPeriodBegin(date)}
              sx={{ width: "100%" }}
            />
            <DateTimePicker
              label="Ending date *"
              value={periodEnd}
              onChange={(date) => setPeriodEnd(date)}
              sx={{ width: "100%" }}
            />
          </Stack>
          <Divider />
          <Typography variant="h6">Optional</Typography>
          <FormLabel>Begin Fulfillment Date (of orders):</FormLabel>
          <DateTimePicker
            label="Begin At"
            value={beginFulfillmentAt}
            onChange={(date) => setBeginFulfillmentAt(date)}
            onClose={() => setBeginFulfillmentAt(null)}
            sx={{ width: "50%" }}
          />
          <Stack direction="row" spacing={2}>
            <FormControlLabel
              control={<Switch />}
              label="Prohibit Charge At Checkout"
              checked={prohibitChargeAtCheckout}
              onChange={() => setProhibitChargeAtCheckout(!prohibitChargeAtCheckout)}
            />
          </Stack>
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}

function AddFulfillmentOption() {
  const [options, setOptions] = React.useState([]);
  // TODO: Figure out better way to track option components for add/delete
  const handleRemoveOption = (optionKey) => {
    setOptions((prev) => {
      const result = prev.filter((op) => {
        return op.key !== optionKey.toString();
      });
      return [...result];
    });
  };
  const handleAddOption = () => {
    setOptions((prev) => {
      return [
        ...prev,
        <NewOption
          key={prev.length}
          onRemoveOption={() => handleRemoveOption(prev.length)}
        />,
      ];
    });
  };
  return (
    <>
      <Button onClick={() => handleAddOption()}>Add Fulfillment option</Button>
      {options.map((op) => op)}
    </>
  );
}

function NewOption({ onRemoveOption }) {
  const [type, setType] = React.useState("");
  const [description, setDescription] = React.useState(translationObj);
  const addingAddress = useToggle(false);
  return (
    <Box component="span" sx={{ p: 2, border: "1px dashed grey" }}>
      <Typography variant="h6">
        Fulfillment Option
        <Button onClick={(e) => onRemoveOption(e)}>Remove</Button>
      </Typography>
      <Stack direction="column" spacing={2}>
        <FormLabel>Type (pickup is commonly used here):</FormLabel>
        <TextField
          value={type}
          variant="outlined"
          onChange={(e) => setType(e.target.value)}
        />
        <FormLabel>Description:</FormLabel>
        <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
          <MultiLingualText
            label="Description"
            fullWidth
            value={description}
            required
            onChange={(description) => setDescription(description)}
          />
        </Stack>
        <Stack direction="column" spacing={2}>
          {addingAddress.isOff ? (
            <Button onClick={() => addingAddress.turnOn()} disabled={addingAddress.isOn}>
              Add Address
            </Button>
          ) : (
            <>
              <Button onClick={() => addingAddress.turnOff()} variant="warning">
                Remove Address
              </Button>
              <OptionAddress editing={addingAddress} />
            </>
          )}
        </Stack>
      </Stack>
    </Box>
  );
}

function OptionAddress({ editing }) {
  const [address1, setAddress1] = React.useState("");
  const [address2, setAddress2] = React.useState("");
  const [city, setCity] = React.useState("");
  const [state, setState] = React.useState("");
  const [postalCode, setPostalCode] = React.useState("");
  const [supportedGeographies, setSupportedGeographies] = React.useState({});

  useMountEffect(() => {
    api
      .getSupportedGeographies()
      .then(api.pickData)
      .then((data) => {
        setSupportedGeographies(data);
        setState(last(data.provinces).value);
      });
  }, []);
  if (!editing) {
    return;
  }
  return (
    <Stack direction="column" spacing={2}>
      <FormLabel>Address</FormLabel>
      <TextField
        value={address1}
        size="small"
        label="Street Address"
        variant="outlined"
        onChange={(e) => setAddress1(e.target.value)}
      />
      <TextField
        value={address2}
        size="small"
        label="Unit or Apartment Number"
        variant="outlined"
        onChange={(e) => setAddress2(e.target.value)}
      />
      <TextField
        value={city}
        size="small"
        label="City"
        variant="outlined"
        onChange={(e) => setCity(e.target.value)}
      />
      <Stack direction="row" spacing={2}>
        <FormControl size="small">
          <Select value={state} label="State" onChange={(e) => setState(e.target.value)}>
            {!!supportedGeographies.provinces &&
              supportedGeographies.provinces.map((st) => (
                <MenuItem key={st.value} value={st.value}>
                  {st.label}
                </MenuItem>
              ))}
          </Select>
        </FormControl>
        <TextField
          value={postalCode}
          size="small"
          label="Zip code"
          variant="outlined"
          onChange={(e) => setPostalCode(e.target.value)}
        />
      </Stack>
    </Stack>
  );
}

const translationObj = { en: "", es: "" };
