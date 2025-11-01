import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import { formatOrNull } from "../modules/dayConfig";
import mergeAt from "../shared/mergeAt";
import withoutAt from "../shared/withoutAt";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import RemoveIcon from "@mui/icons-material/Remove";
import { Box, FormHelperText, FormLabel, Icon, Stack, TextField } from "@mui/material";
import Button from "@mui/material/Button";
import React from "react";

export default function ProgramForm({
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
      title={isCreate ? "Create a Program" : "Update a Program"}
      subtitle="Programs represent goods that can be sold or offered by suma.
      They contain goods and services like food offerings and third-party services, e.g. Lime.
      They are displayed to member dashboards. You can enroll members or organizations into a program
      by later creating a Program Enrollment."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ImageFileInput
          image={resource.image}
          caption={resource.imageCaption}
          onImageChange={(f) => setField("image", f)}
          onCaptionChange={(f) => setField("imageCaption", f)}
          required={isCreate}
        />
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
        <FormLabel>Description</FormLabel>
        <MultiLingualText
          {...register("description")}
          label="Description"
          fullWidth
          value={resource.description}
          required
          multiline
          onChange={(v) => setField("description", v)}
        />
        <FormLabel>App Link</FormLabel>
        <FormHelperText>
          Useful for linking members to promotion pages, '/food/1' would link to
          'app.mysuma.org/app/food/1'.
        </FormHelperText>
        <TextField
          {...register("appLink")}
          fullWidth
          value={resource.appLink}
          label="App link"
          onChange={setFieldFromInput}
        />
        <ResponsiveStack>
          <MultiLingualText
            {...register("app_link_text")}
            label="App Link Text"
            fullWidth
            value={resource.appLinkText}
            onChange={(v) => setField("appLinkText", v)}
          />
        </ResponsiveStack>
        <FormLabel>Timings</FormLabel>
        <FormHelperText>
          Member or organization can access a program between the open and close times.
        </FormHelperText>
        <ResponsiveStack alignItems="center" divider={<RemoveIcon />}>
          <SafeDateTimePicker
            label="Program Opens *"
            value={resource.periodBegin}
            onChange={(v) => setField("periodBegin", formatOrNull(v))}
          />
          <SafeDateTimePicker
            label="Program Closes *"
            value={resource.periodEnd}
            onChange={(v) => setField("periodEnd", formatOrNull(v))}
          />
        </ResponsiveStack>
        <FormLabel>Ordering</FormLabel>
        <TextField
          name="ordinal"
          value={resource.ordinal}
          type="number"
          label="Ordinal"
          helperText="Programs are listed from lower to higher ordinal values in the dashboard."
          fullWidth
          onChange={setFieldFromInput}
        />
        <FormLabel>Other</FormLabel>
        <TextField
          {...register("lyftPassProgramId")}
          label="Lyft Pass Program"
          name="lyftPassProgramId"
          value={resource.lyftPassProgramId}
          helperText="Set this for programs that are for Lyft Pass enrollment."
          fullWidth
          onChange={setFieldFromInput}
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
