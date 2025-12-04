import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import ResponsiveStack from "../components/ResponsiveStack";
import { useGlobalApiState } from "../hooks/globalApiState";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import withoutAt from "../shared/withoutAt";
import {
  Card,
  CardContent,
  Checkbox,
  Divider,
  FormControl,
  FormHelperText,
  FormLabel,
  InputLabel,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  MenuItem,
  Select,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import debounce from "lodash/debounce";
import React from "react";

export default function MarketingSmsBroadcastEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getMarketingSmsBroadcast}
      apiUpdate={api.updateMarketingSmsBroadcast}
      Form={EditForm}
    />
  );
}

function EditForm({ resource, setField, setFieldFromInput, register, isBusy, onSubmit }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const [preview, setPreview] = React.useState(resource.preview);

  const previewDebounced = React.useMemo(
    () =>
      debounce(
        (body) =>
          api
            .previewMarketingSmsBroadcast(body)
            .then((r) => setPreview(r.data))
            .catch(enqueueErrorSnackbar),
        500
      ),
    [enqueueErrorSnackbar]
  );

  const handleBodyChange = React.useCallback(
    (e, lang) => {
      const newBody = { ...resource.body, [lang]: e.target.value };
      setField("body", newBody);
      previewDebounced(newBody);
    },
    [previewDebounced, resource.body, setField]
  );

  if (resource.sentAt) {
    return (
      <Typography>This broadcast has already been sent and cannot be edited.</Typography>
    );
  }

  return (
    <FormLayout
      title="Update SMS Broadcast"
      subtitle="Broadcasts are sent to all members on all the associated lists.
      The body can use merge fields, including {{name}}, {{phone}}, and {{email}}.
      The body preview is done using your current user."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>SMS Broadcast</FormLabel>
        <TextField
          {...register("label")}
          label="Label"
          name="label"
          value={resource.label || ""}
          type="text"
          variant="outlined"
          fullWidth
          onChange={setFieldFromInput}
        />
        <ResponsiveStack>
          <FormControl sx={{ flex: 1 }}>
            <InputLabel shrink>Sending Number</InputLabel>
            <Select
              {...register("sendingNumber")}
              label="Sending Number"
              name="sendingNumber"
              value={resource.sendingNumber || ""}
              displayEmpty
              onChange={setFieldFromInput}
            >
              <MenuItem value="">Blank - Will not send</MenuItem>
              {resource.availableSendingNumbers.map(({ name, number, formatted }) => (
                <MenuItem key={name} value={number}>
                  {name}: {formatted}
                </MenuItem>
              ))}
            </Select>
            <FormHelperText>
              What number will this send from? Note that Marketing numbers generally
              process opt-outs, while Transactional numbers usually bypass preferences.
              Setting no number here will create a broadcast that will not send anything.
            </FormHelperText>
          </FormControl>
          <FormControl sx={{ flex: 1 }}>
            <InputLabel shrink>Preferences Opt-Out</InputLabel>
            <OptoutFieldSelect
              {...register("preferencesOptoutField")}
              label="Preferences Opt-Out"
              name="preferencesOptoutField"
              value={resource.preferencesOptoutField}
              onChange={setFieldFromInput}
            />
            <FormHelperText>
              Which message preferences field should this broadcast honor? Dispatches to
              users who have this opt-out field set, will not be sent.
            </FormHelperText>
          </FormControl>
        </ResponsiveStack>
        <Divider />
        <ResponsiveStack>
          <BodyPreview
            register={register}
            resource={resource}
            onBodyChange={handleBodyChange}
            preview={preview}
            language="en"
          />
          <BodyPreview
            register={register}
            resource={resource}
            onBodyChange={handleBodyChange}
            preview={preview}
            language="es"
          />
        </ResponsiveStack>
        <MarketingLists
          allLists={resource.allLists}
          lists={resource.lists}
          setLists={(v) => setField("lists", v)}
        />
      </Stack>
    </FormLayout>
  );
}

function BodyPreview({ register, resource, onBodyChange, language, preview }) {
  const payload = preview[`${language}Payload`];
  return (
    <Stack sx={{ flex: 1 }}>
      <TextField
        {...register(`body.${language}`)}
        label={`Body (${language})`}
        fullWidth
        value={resource.body[language]}
        required
        multiline
        rows={5}
        onChange={(e) => onBodyChange(e, language)}
      />
      <Card sx={{ mt: 1 }}>
        <CardContent>
          <Typography variant="subtitle2">Characters: {payload.characters}</Typography>
          <Typography variant="subtitle2">Segments: {payload.segments}</Typography>
          <Typography variant="subtitle2" gutterBottom>
            Cost: ${payload.cost}
          </Typography>
          <Typography>{preview[language]}</Typography>
        </CardContent>
      </Card>
    </Stack>
  );
}

function MarketingLists({ allLists, lists, setLists }) {
  const checkedListIds = lists.map((l) => l.id);

  const handleToggle = (value) => {
    const existingCheckedIdx = checkedListIds.indexOf(value);
    let newlyCheckedLists;
    if (existingCheckedIdx > -1) {
      newlyCheckedLists = withoutAt(lists, existingCheckedIdx);
    } else {
      newlyCheckedLists = [...lists, allLists.find((l) => l.id === value)];
    }
    setLists(newlyCheckedLists);
  };

  return (
    <Card variant="outlined">
      <CardContent>
        <FormLabel>Recipient Lists</FormLabel>
        <List dense>
          {allLists.map(({ id, label }) => (
            <ListItem key={id} disablePadding dense>
              <ListItemButton dense onClick={() => handleToggle(id)}>
                <ListItemIcon>
                  <Checkbox
                    edge="start"
                    checked={checkedListIds.includes(id)}
                    tabIndex={-1}
                    disableRipple
                  />
                </ListItemIcon>
                <ListItemText primary={label} />
              </ListItemButton>
            </ListItem>
          ))}
        </List>
      </CardContent>
    </Card>
  );
}

const OptoutFieldSelect = React.forwardRef(function OptoutFieldSelect({ ...rest }, ref) {
  const data = useGlobalApiState(
    (data, ...args) =>
      api.getMarketingSmsBroadcastPreferencesOptoutOptions({ ...data }, ...args),
    { items: [] }
  );

  return (
    <Select displayEmpty {...rest}>
      {data.items.map(({ name, value }) => (
        <MenuItem key={value} value={value}>
          {name}
        </MenuItem>
      ))}
    </Select>
  );
});
