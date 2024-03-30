import api from "../api";
import formHelpers from "../modules/formHelpers";
import useMountEffect from "../shared/react/useMountEffect";
import ResponsiveStack from "./ResponsiveStack";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import {
  Button,
  FormControl,
  FormLabel,
  Icon,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  TextField,
} from "@mui/material";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function AddressInputs({ address, onFieldChange }) {
  function handleFieldChange(a) {
    onFieldChange({ address: { ...address, ...a } });
  }
  function handleAddressOn() {
    onFieldChange({ address: formHelpers.initialAddress });
  }
  function handleAddressOff() {
    onFieldChange({ address: null });
  }
  return (
    <Stack spacing={2}>
      {isEmpty(address) ? (
        <Button onClick={handleAddressOn}>
          <AddIcon /> Add Address
        </Button>
      ) : (
        <>
          <AddressFields address={address} onFieldChange={(a) => handleFieldChange(a)} />
          <Button onClick={handleAddressOff} variant="warning">
            <Icon color="warning">
              <DeleteIcon />
            </Icon>
            Remove Address
          </Button>
        </>
      )}
    </Stack>
  );
}

function AddressFields({ address, onFieldChange }) {
  const [supportedGeographies, setSupportedGeographies] = React.useState({});

  useMountEffect(() => {
    api
      .getSupportedGeographies()
      .then(api.pickData)
      .then((data) => {
        setSupportedGeographies(data);
      });
  }, []);

  if (!address) {
    return null;
  }
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
