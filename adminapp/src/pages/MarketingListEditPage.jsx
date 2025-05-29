import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useMountEffect from "../shared/react/useMountEffect";
import AddIcon from "@mui/icons-material/Add";
import ClearIcon from "@mui/icons-material/Clear";
import RemoveIcon from "@mui/icons-material/Remove";
import SearchIcon from "@mui/icons-material/Search";
import {
  Card,
  CardContent,
  CircularProgress,
  FormLabel,
  InputAdornment,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Stack,
  TextField,
} from "@mui/material";
import IconButton from "@mui/material/IconButton";
import debounce from "lodash/debounce";
import React from "react";

export default function MarketingListEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getMarketingList}
      apiUpdate={api.updateMarketingList}
      Form={EditForm}
    />
  );
}

function EditForm({ resource, setField, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Update Marketing List"
      subtitle="Broadcasts are sent to lists. We should generally use
      Managed (auto-created and updated) lists,
      but sometimes we want manual lists too."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>Marketing List</FormLabel>
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
        <Members members={resource.members} setMembers={(v) => setField("members", v)} />
      </Stack>
    </FormLayout>
  );
}

function Members({ members, setMembers }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const [allMembers, setAllMembers] = React.useState([]);
  const [search, setSearchInner] = React.useState("");
  const { busy, isBusy, notBusy } = useBusy(true);

  const getMembersDebounced = React.useMemo(
    () =>
      debounce(
        (data) =>
          api
            .getMembers(data)
            .then((r) => setAllMembers(r.data.items))
            .catch(enqueueErrorSnackbar)
            .finally(notBusy),
        500
      ),
    [enqueueErrorSnackbar, notBusy]
  );

  const setSearch = React.useCallback(
    (v) => {
      busy();
      setSearchInner(v);
      getMembersDebounced({ search: v });
    },
    [busy, getMembersDebounced]
  );

  useMountEffect(() => getMembersDebounced());

  const currentMemberIds = members.map(({ id }) => id);
  const eligibleMembers = allMembers.filter((m) => !currentMemberIds.includes(m.id));

  function handleAdd(m) {
    setMembers([...members, m]);
  }

  function handleRemove(m) {
    const without = members.filter((m2) => m2.id !== m.id);
    setMembers(without);
  }

  return (
    <>
      <Card variant="outlined">
        <CardContent>
          <FormLabel>List Members</FormLabel>
          <List dense>
            {members.length === 0 && (
              <ListItem disablePadding dense>
                <ListItemText primary="(Empty)" />
              </ListItem>
            )}
            {members.map((m) => (
              <ListItem key={m.id} disablePadding dense>
                <ListItemButton onClick={() => handleRemove(m)} dense>
                  <ListItemIcon>
                    <RemoveIcon />
                  </ListItemIcon>
                  <ListItemText primary={formatMember(m)} />
                </ListItemButton>
              </ListItem>
            ))}
          </List>
        </CardContent>
      </Card>
      <Card variant="outlined">
        <CardContent>
          <Stack gap={2}>
            <TextField
              variant="outlined"
              type="search"
              value={search}
              placeholder="Search"
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={() => setSearch("")}
                      onMouseDown={() => setSearch("")}
                      edge="end"
                    >
                      <ClearIcon />
                    </IconButton>
                  </InputAdornment>
                ),
              }}
              onChange={(e) => setSearch(e.target.value)}
            />
            <FormLabel>Add Members</FormLabel>
          </Stack>
          <List dense>
            {isBusy ? (
              <ListItem disablePadding dense>
                <CircularProgress />
              </ListItem>
            ) : (
              <>
                {eligibleMembers.map((m) => (
                  <ListItem key={m.id} disablePadding dense>
                    <ListItemButton onClick={() => handleAdd(m)} dense>
                      <ListItemIcon>
                        <AddIcon edge="start" tabIndex={-1} />
                      </ListItemIcon>
                      <ListItemText primary={formatMember(m)} />
                    </ListItemButton>
                  </ListItem>
                ))}
                {eligibleMembers.length === 0 && (
                  <ListItem disablePadding dense>
                    <ListItemText primary="No results" />
                  </ListItem>
                )}
              </>
            )}
          </List>
        </CardContent>
      </Card>
    </>
  );
}

function formatMember(m) {
  const phone = m.formattedPhone;
  if (m.name) {
    return `${m.id}: ${m.name}: ${phone}`;
  }
  return `${m.id}: ${phone}`;
}
