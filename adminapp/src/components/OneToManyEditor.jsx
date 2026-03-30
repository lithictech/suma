import mergeAt from "../shared/mergeAt";
import withoutAt from "../shared/withoutAt";
import AutocompleteSearch from "./AutocompleteSearch";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import { Box, FormLabel, Icon, Stack } from "@mui/material";
import Button from "@mui/material/Button";
import React from "react";

export default function OneToManyEditor({ title, items, setItems, apiItemSearch }) {
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
          name={o.label}
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
