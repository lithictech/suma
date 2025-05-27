import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import ResponsiveStack from "../components/ResponsiveStack";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import withoutAt from "../shared/withoutAt";
import {
  Card,
  CardContent,
  Checkbox,
  FormLabel,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import debounce from "lodash/debounce";
import React from "react";

export default function MarketingSmsCampaignEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getMarketingSmsCampaign}
      apiUpdate={api.updateMarketingSmsCampaign}
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
            .previewMarketingSmsCampaign(body)
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
      <Typography>This campaign has already been sent and cannot be edited.</Typography>
    );
  }

  return (
    <FormLayout
      title="Update SMS Campaign"
      subtitle="Campaigns are sent to all members on all the associated lists.
      The body can use merge fields, including {{name}}, {{phone}}, and {{email}}.
      The body preview is done using your current user."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>SMS Campaign</FormLabel>
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
    <Stack sx={{ width: "50%" }}>
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
