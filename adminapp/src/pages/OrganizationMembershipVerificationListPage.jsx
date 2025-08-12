import api from "../api";
import AdminLink from "../components/AdminLink";
import InlineEditField from "../components/InlineEditField";
import Link from "../components/Link";
import OrganizationMembership from "../components/OrganizationMembership";
import ResourceTable from "../components/ResourceTable";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import formatDate from "../modules/formatDate";
import membershipVerificationDuplicateRiskColor from "../modules/membershipVerificationDuplicateRiskColor";
import relativeLink from "../modules/relativeLink";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import useToggle from "../shared/react/useToggle";
import ArrowRightIcon from "@mui/icons-material/ArrowRight";
import CreateIcon from "@mui/icons-material/Create";
import DraftsIcon from "@mui/icons-material/Drafts";
import PolicyIcon from "@mui/icons-material/Policy";
import ReplyIcon from "@mui/icons-material/Reply";
import SendIcon from "@mui/icons-material/Send";
import LoadingButton from "@mui/lab/LoadingButton";
import {
  Card,
  CardContent,
  Fade,
  FormControl,
  InputLabel,
  Select,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import Button from "@mui/material/Button";
import ButtonGroup from "@mui/material/ButtonGroup";
import ClickAwayListener from "@mui/material/ClickAwayListener";
import Grow from "@mui/material/Grow";
import MenuItem from "@mui/material/MenuItem";
import MenuList from "@mui/material/MenuList";
import Paper from "@mui/material/Paper";
import Popper from "@mui/material/Popper";
import TrapFocus from "@mui/material/Unstable_TrapFocus";
import { useTheme } from "@mui/styles";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function OrganizationMembershipVerificationListPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const { params, page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getList = React.useCallback(() => {
    return api.getOrganizationMembershipVerifications({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
      status: params.get("status"),
    });
  }, [order, orderBy, page, perPage, search, params]);

  const {
    state: rawListResponse,
    loading: listLoading,
    asyncFetch,
  } = useAsyncFetch(getList, { default: {} });
  const [updatedListResponses, setUpdatedListResponses] = React.useState({});

  const listResponse = { ...rawListResponse?.data, items: [] };
  (rawListResponse?.data?.items || []).forEach((r) => {
    const item = updatedListResponses[r.id] || r;
    listResponse.items.push({ key: `${item.id}t`, item, top: true });
    listResponse.items.push({ key: `${item.id}b`, item, top: false });
  });

  const frontEnabled = rawListResponse?.headers?.get("Suma-Front-Enabled");
  const eventsToken = rawListResponse?.headers?.get("Suma-Events-Token");

  const makeApiCall = React.useCallback(
    (func, params) => {
      return func(params, { headers: { "Suma-Events-Token": eventsToken } })
        .tap((r) =>
          setUpdatedListResponses({ ...updatedListResponses, [r.data.id]: r.data })
        )
        .tapCatch(enqueueErrorSnackbar);
    },
    [enqueueErrorSnackbar, eventsToken, updatedListResponses]
  );

  function handleEventChangesClicked() {
    setListQueryParams({ page: 0 });
    setNotedVerificationId(null);
    asyncFetch({ page: 0 });
  }

  const [notedVerificationId, setNotedVerificationId] = React.useState(null);
  const notedVerification = listResponse.items
    .map((t) => t.item)
    .find((v) => v.id === notedVerificationId);

  function colPropsCombineRows(c) {
    return c.top ? { sx: { borderBottom: "none" } } : { sx: { paddingTop: 0 } };
  }

  return (
    <>
      <ResourceTable
        page={page}
        perPage={perPage}
        search={search}
        order={order}
        orderBy={orderBy}
        title="Verifications"
        eventsUrl="/events/organization_membership_verifications"
        eventsToken={eventsToken}
        listResponse={listResponse}
        listLoading={listLoading}
        tableProps={{ sx: { minWidth: 650 }, size: "small" }}
        onParamsChange={setListQueryParams}
        onEventChangesClicked={handleEventChangesClicked}
        filters={[
          <FormControl key="status">
            <InputLabel>Status</InputLabel>
            <Select
              value={params.get("status") || "todo"}
              label="Status"
              size="small"
              onChange={(e) =>
                setListQueryParams({}, { status: e.target.value, page: 0 })
              }
            >
              <MenuItem value="todo">To-do</MenuItem>
              <MenuItem value="verified">Verified</MenuItem>
              <MenuItem value="ineligible">Ineligible</MenuItem>
              <MenuItem value="abandoned">Abandoned</MenuItem>
              <MenuItem value="all">All</MenuItem>
            </Select>
          </FormControl>,
        ]}
        columns={[
          {
            id: "status",
            label: "Status",
            sortable: true,
            props: colPropsCombineRows,
            render: (c) => {
              const isNoted = c.item.id === notedVerification?.id;
              return c.top ? (
                <StatusCell
                  verification={c.item}
                  isNoted={isNoted}
                  makeApiCall={makeApiCall}
                />
              ) : (
                <Stack direction="row" alignItems="center" gap={1}>
                  <Button
                    variant={isNoted ? "contained" : "outlined"}
                    onClick={() => setNotedVerificationId(isNoted ? null : c.item.id)}
                  >
                    Notes{c.item.notes.length > 0 && ` (${c.item.notes.length})`}
                  </Button>
                  <DuplicateBadge verification={c.item} />
                </Stack>
              );
            },
          },
          {
            id: "member",
            label: "Member",
            align: "left",
            sortable: true,
            props: colPropsCombineRows,
            render: (c) =>
              c.top ? (
                <AdminLink model={c.item.membership.member}>
                  {c.item.membership.member.name}
                </AdminLink>
              ) : (
                <MemberOutreach
                  verification={c.item}
                  frontEnabled={frontEnabled}
                  makeApiCall={makeApiCall}
                />
              ),
          },
          {
            id: "phone",
            label: "Phone",
            align: "left",
            sortable: true,
            props: colPropsCombineRows,
            render: (c) => (c.top ? c.item.membership.member.formattedPhone : null),
          },
          {
            id: "organization",
            label: "Organization",
            align: "left",
            sortable: true,
            props: colPropsCombineRows,
            render: (c) =>
              c.top ? (
                <OrganizationMembership membership={c.item.membership} />
              ) : (
                <PartnerOutreach
                  verification={c.item}
                  frontEnabled={frontEnabled}
                  makeApiCall={makeApiCall}
                />
              ),
          },
          {
            id: "created_at",
            label: "Registered",
            align: "left",
            sortable: true,
            props: colPropsCombineRows,
            render: (c) =>
              c.top ? formatDate(c.item.membership.member.createdAt) : null,
          },
        ]}
      />
      <NotesViewer verification={notedVerification} makeApiCall={makeApiCall} />
    </>
  );
}

const eventStyles = {
  reject: { color: "error.main" },
  approve: { color: "success.main" },
};

const statusBtnProps = {
  created: { variant: "contained", color: "secondary" },
  in_progress: { variant: "contained", color: "secondary" },
  ineligible: { variant: "outlined", color: "error" },
  abandoned: { variant: "outlined", color: "secondary" },
  verified: { variant: "outlined", color: "success" },
};

function StatusCell({ verification, makeApiCall }) {
  const handleTransition = React.useCallback(
    (row, option) => {
      makeApiCall(api.transitionOrganizationMembershipVerification, {
        id: row.id,
        event: option,
      });
    },
    [makeApiCall]
  );
  return (
    <StatusPicker
      value={verification.status}
      options={verification.availableEvents}
      href={relativeLink(verification.adminLink)[0]}
      onOptionSelected={(o) => handleTransition(verification, o)}
    />
  );
}

function StatusPicker({ value, options, onOptionSelected, href }) {
  const toggle = useToggle();
  const anchorRef = React.useRef(null);

  const handleMenuItemClick = (event, option) => {
    onOptionSelected(option);
    toggle.turnOff();
  };

  const handleClose = (event) => {
    if (anchorRef.current && anchorRef.current.contains(event.target)) {
      return;
    }
    toggle.turnOff();
  };

  const bprops = {
    size: "small",
    variant: "contained",
    ...statusBtnProps[value],
  };

  return (
    <>
      <ButtonGroup {...bprops} ref={anchorRef}>
        <Button component={Link} href={href} sx={{ display: "flex", flex: 1 }}>
          {value}
        </Button>
        <Button size="small" onClick={toggle.toggle}>
          <ArrowRightIcon />
        </Button>
      </ButtonGroup>
      <Popper
        sx={{ zIndex: 1 }}
        open={toggle.isOn}
        anchorEl={anchorRef.current}
        role={undefined}
        transition
        disablePortal
        placement="bottom-end"
      >
        {({ TransitionProps }) => (
          <Grow
            {...TransitionProps}
            style={{
              transformOrigin: "center top",
            }}
          >
            <Paper>
              <ClickAwayListener onClickAway={handleClose}>
                <MenuList id="split-button-menu" autoFocusItem>
                  {options.map((option) => (
                    <MenuItem
                      key={option}
                      sx={{ textTransform: "capitalize", ...eventStyles[option] }}
                      onClick={(event) => handleMenuItemClick(event, option)}
                    >
                      <ArrowRightIcon />
                      {option}
                    </MenuItem>
                  ))}
                </MenuList>
              </ClickAwayListener>
            </Paper>
          </Grow>
        )}
      </Popper>
    </>
  );
}

function MemberOutreach({ verification, frontEnabled, makeApiCall }) {
  function handleBegin() {
    return makeApiCall(api.beginOrganizationMembershipVerificationMemberOutreach, {
      id: verification.id,
    }).tap((r) => window.open(r.data.frontMemberConversationStatus.webUrl, "_blank"));
  }
  return (
    <FrontConvoStatus
      {...verification.frontMemberConversationStatus}
      frontEnabled={frontEnabled}
      onBegin={handleBegin}
    />
  );
}

function PartnerOutreach({ verification, frontEnabled, makeApiCall }) {
  function handleBegin() {
    return makeApiCall(api.beginOrganizationMembershipVerificationPartnerOutreach, {
      id: verification.id,
    }).tap((r) => window.open(r.data.frontPartnerConversationStatus.webUrl, "_blank"));
  }
  return (
    <FrontConvoStatus
      {...verification.frontPartnerConversationStatus}
      frontEnabled={frontEnabled}
      onBegin={handleBegin}
    />
  );
}

function FrontConvoStatus({
  webUrl,
  waitingOnAdmin,
  initialDraft,
  lastUpdatedAt,
  frontEnabled,
  onBegin,
}) {
  const acting = useToggle();
  function handleClick(e) {
    e.preventDefault();
    acting.turnOn();
    onBegin().finally(acting.turnOff);
  }
  // [webUrl, initialDraft, waitingOnAdmin, lastUpdatedAt] = getTestingProps();
  let Icon, text;
  const bprops = { href: webUrl, target: "_blank" };
  if (!webUrl) {
    Icon = CreateIcon;
    text = "Begin";
    bprops.href = bprops.target = null;
    bprops.variant = "contained";
    bprops.color = "primary";
    bprops.onClick = handleClick;
  } else if (initialDraft) {
    Icon = DraftsIcon;
    text = "Draft";
    bprops.variant = "contained";
    bprops.color = "success";
  } else if (waitingOnAdmin) {
    Icon = ReplyIcon;
    text = formatDate(lastUpdatedAt, { template: "ddd MMM D h:mma" });
    bprops.variant = "contained";
    bprops.color = "success";
  } else {
    Icon = SendIcon;
    text = formatDate(lastUpdatedAt, { template: "ddd MMM D h:mma" });
    bprops.variant = "outlined";
    bprops.color = "secondary";
  }
  return (
    <div>
      <LoadingButton
        size="small"
        loading={acting.isOn}
        disabled={!frontEnabled}
        {...bprops}
      >
        <Icon sx={{ marginRight: 1 }} />
        {text}
      </LoadingButton>
    </div>
  );
}

function DuplicateBadge({ verification }) {
  const risk = verification.duplicateRisk;
  if (!risk) {
    return null;
  }
  return (
    <AdminLink model={verification}>
      <PolicyIcon color={membershipVerificationDuplicateRiskColor(risk)} />
    </AdminLink>
  );
}

// Use this to see all the permutations of fields on the list buttons,
// which can be difficult to test out with Front in real usage.
// eslint-disable-next-line no-unused-vars
function getTestingProps() {
  const r = Math.random();
  if (r < 0.25) {
    return ["", false, false, null]; // Not created
  } else if (r < 0.5) {
    return ["draft", true, false, null]; // created initial draft
  } else if (r < 0.75) {
    return ["waitonmember", false, false, "2012-11-22T12:00:00Z"]; // sent, waiting on member
  } else {
    return ["waitonadmin", false, true, "2012-11-22T12:00:00Z"]; // waiting on response
  }
}

function NotesViewer({ verification, makeApiCall }) {
  const [noteContent, setNoteContent] = React.useState();
  const saving = useToggle();
  const theme = useTheme();

  function handleNoteSave(e) {
    e.preventDefault();
    saving.turnOn();
    makeApiCall(api.addOrganizationMembershipVerificationNote, {
      id: verification.id,
      content: noteContent,
    })
      .then(() => setNoteContent(""))
      .finally(saving.turnOff);
  }
  function handleAccountNumberSave(v) {
    return makeApiCall(api.updateOrganizationMembershipVerification, {
      id: verification.id,
      accountNumber: v.accountNumber,
    });
  }
  return (
    <React.Fragment>
      <TrapFocus open disableAutoFocus disableEnforceFocus>
        <Fade appear={false} in={!!verification}>
          <Paper
            role="dialog"
            square
            variant="outlined"
            tabIndex={-1}
            sx={{
              position: "sticky",
              bottom: 0,
              left: 0,
              right: 0,
              m: 0,
              p: 2,
              borderWidth: 0,
              borderTopWidth: 1,
              zIndex: 1,
              height: "25vh",
              overflow: "scroll",
              boxShadow: "0px -3px 6px -1px rgba(0, 0, 0, 0.5)",
              clipPath: "inset(-30px 0 0 0)",
            }}
          >
            <Stack direction="row" justifyContent="space-between" gap={2}>
              <Stack gap={1} sx={{ flex: 1 }}>
                {verification && (
                  <Card key={verification.id}>
                    <CardContent sx={{ padding: `${theme.spacing(1)} !important` }}>
                      <InlineEditField
                        resource="organization_membership_verification"
                        renderDisplay={
                          <span>Account/EBT: {verification.accountNumber}</span>
                        }
                        initialEditingState={{
                          accountNumber: verification.accountNumber,
                        }}
                        renderEdit={(st, set) => (
                          <TextField
                            size="small"
                            value={st.accountNumber || ""}
                            onChange={(e) =>
                              set({
                                ...verification,
                                accountNumber: e.target.value,
                              })
                            }
                          />
                        )}
                        onSave={(v) => handleAccountNumberSave(v)}
                      />
                    </CardContent>
                  </Card>
                )}
                {isEmpty(verification?.notes) && (
                  <Typography variant="subtitle2">
                    Add a note using the note editor.
                  </Typography>
                )}
                {verification?.notes.map((note) => (
                  <Card key={note.id}>
                    <CardContent sx={{ padding: `${theme.spacing(1)} !important` }}>
                      <div dangerouslySetInnerHTML={{ __html: note.contentHtml }}></div>
                      <Typography variant="caption">
                        {note.creator?.name} at {formatDate(note.createdAt)}
                      </Typography>
                      {note.editor && (
                        <Typography variant="caption">
                          Edited by {note.editor.name} at {formatDate(note.editedAt)}
                        </Typography>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </Stack>
              <Stack gap={1} sx={{ flex: 1 }}>
                <Typography variant="subtitle2">
                  Notes for {verification?.membership.member.name} in{" "}
                  {verification?.membership.organizationLabel}
                </Typography>
                <TextField
                  label="Add Note"
                  name="content"
                  value={noteContent || ""}
                  type="text"
                  variant="outlined"
                  fullWidth
                  multiline
                  rows={4}
                  onChange={(e) => setNoteContent(e.target.value)}
                />
                <LoadingButton
                  variant="contained"
                  loading={saving.isOn}
                  onClick={handleNoteSave}
                  disabled={!noteContent}
                >
                  Save
                </LoadingButton>
              </Stack>
            </Stack>
          </Paper>
        </Fade>
      </TrapFocus>
    </React.Fragment>
  );
}
