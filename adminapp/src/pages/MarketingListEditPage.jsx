import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useMountEffect from "../shared/react/useMountEffect";
import AddIcon from "@mui/icons-material/Add";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import ClearIcon from "@mui/icons-material/Clear";
import RemoveIcon from "@mui/icons-material/Remove";
import RemoveCircleOutlineIcon from "@mui/icons-material/RemoveCircleOutline";
import SearchIcon from "@mui/icons-material/Search";
import {
  Box,
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
  Typography,
} from "@mui/material";
import Button from "@mui/material/Button";
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
      isBusy={isBusy}
      style={{ maxWidth: null }}
      onSubmit={onSubmit}
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

  function handleAddAll() {
    setMembers([...members, ...eligibleMembers]);
  }

  function handleRemoveAll() {
    setMembers([]);
  }

  function handleRemove(m) {
    const without = members.filter((m2) => m2.id !== m.id);
    setMembers(without);
  }

  return (
    <Stack direction={{ xs: "column", lg: "row" }} gap={2}>
      <Card variant="outlined" sx={{ flex: 1 }}>
        <CardContent>
          <Stack gap={1}>
            <Typography variant="h6" color="secondary">
              List Members ({members.length})
            </Typography>
            <BulkActionButton
              disabled={members.length === 0}
              startIcon={<RemoveCircleOutlineIcon />}
              onClick={handleRemoveAll}
            >
              Remove all members
            </BulkActionButton>
            <MemberList>
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
            </MemberList>
          </Stack>
        </CardContent>
      </Card>
      <Card variant="outlined" sx={{ flex: 1 }}>
        <CardContent>
          <Stack gap={1}>
            <TextField
              variant="outlined"
              type="search"
              value={search}
              placeholder="Search"
              helperText={`${eligibleMembers.length || "No"} results`}
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
            <BulkActionButton
              startIcon={<AddCircleOutlineIcon />}
              disabled={eligibleMembers.length === 0}
              onClick={handleAddAll}
            >
              Add all members
            </BulkActionButton>
            <MemberList>
              {isBusy ? (
                <ListItem disablePadding dense>
                  <CircularProgress />
                </ListItem>
              ) : (
                eligibleMembers.map((m) => (
                  <ListItem key={m.id} disablePadding dense>
                    <ListItemButton onClick={() => handleAdd(m)} dense>
                      <ListItemIcon>
                        <AddIcon edge="start" tabIndex={-1} />
                      </ListItemIcon>
                      <ListItemText primary={formatMember(m)} />
                    </ListItemButton>
                  </ListItem>
                ))
              )}
            </MemberList>
          </Stack>
        </CardContent>
      </Card>
    </Stack>
  );
}

function MemberList({ children }) {
  return (
    <div style={{ position: "relative" }}>
      <List dense sx={{ maxHeight: { xs: 500, lg: "60vh" }, overflow: "scroll" }}>
        {children}
        <ListItem sx={{ height: "20px" }}></ListItem>
      </List>
      <div
        style={{
          width: "calc(100% - 10px)",
          position: "absolute",
          backgroundImage: "linear-gradient(0deg, white, transparent)",
          // background: "red",
          pointerEvents: "none",
          height: 60,
          bottom: 0,
        }}
      ></div>
    </div>
  );
}

function BulkActionButton(props) {
  return (
    <Box mt={1}>
      <Button
        variant="outlined"
        color="secondary"
        size="small"
        sx={{ borderRadius: 100 }}
        {...props}
      />
    </Box>
  );
}

function formatMember(m) {
  const phone = m.formattedPhone;
  if (m.name) {
    return `${m.id}: ${m.name}: ${phone}`;
  }
  return `${m.id}: ${phone}`;
}
