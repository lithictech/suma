import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import mergeAt from "../shared/mergeAt";
import withoutAt from "../shared/withoutAt";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import { Box, FormLabel, Icon, Stack } from "@mui/material";
import Button from "@mui/material/Button";
import React from "react";

export default function VendibleGroupForm({
  isCreate,
  resource,
  setField,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create a Vendible Group" : "Update a Vendible Group"}
      subtitle="Groupings of things that can be sold or offered by suma.
      This is usually things like grouping commerce offerings into 'Farmers Markets'.
      They are displayed to member dashboards. Commerce offerings and vendor services
      are the available vendibles that can be added to this group."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>Name</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("name")}
            label="Name"
            fullWidth
            value={resource.name}
            required
            onChange={(v) => setField("name", v)}
          />
        </ResponsiveStack>
        <ModelItems
          title="Vendor Service"
          items={resource.vendorServices}
          setItems={(vs) => setField("vendorServices", vs)}
          apiItemSearch={api.searchVendorServices}
        />
        <ModelItems
          title="Commerce Offering"
          items={resource.commerceOfferings}
          setItems={(o) => setField("commerceOfferings", o)}
          apiItemSearch={api.searchCommerceOffering}
        />
      </Stack>
    </FormLayout>
  );
}

function ModelItems({ title, items, setItems, apiItemSearch }) {
  const handleAdd = () => {
    setItems([...items, { id: 0 }]);
  };
  const handleRemove = (index) => {
    setItems(withoutAt(items, index));
  };
  function handleChange(index, fields) {
    setItems(mergeAt(items, index, fields));
  }
  return (
    <>
      <FormLabel>{`${title}s`}</FormLabel>
      {items?.map((o, i) => (
        <ModelItem
          key={i + title}
          {...o}
          name={o.name || o.description?.en}
          title={title}
          index={i}
          apiItemSearch={apiItemSearch}
          onChange={(fields) => handleChange(i, fields)}
          onRemove={() => handleRemove(i)}
        />
      ))}
      <Button onClick={handleAdd}>
        <AddIcon /> Add {title}
      </Button>
    </>
  );
}

function ModelItem({ index, title, name, apiItemSearch, onChange, onRemove }) {
  return (
    <Box sx={{ p: 2, border: "1px dashed grey" }}>
      <Stack
        direction="row"
        spacing={2}
        mb={2}
        sx={{ justifyContent: "space-between", alignItems: "center" }}
      >
        <FormLabel>
          {title} {index + 1}
        </FormLabel>
        <Button onClick={onRemove} variant="warning" sx={{ marginLeft: "5px" }}>
          <Icon color="warning">
            <DeleteIcon />
          </Icon>
          Remove
        </Button>
      </Stack>
      <AutocompleteSearch
        label={title}
        value={name || ""}
        fullWidth
        required
        search={apiItemSearch}
        style={{ flex: 1 }}
        onValueSelect={(vs) => onChange({ ...vs })}
      />
    </Box>
  );
}
