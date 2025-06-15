import api from "../api";
import AdminLink from "../components/AdminLink";
import OrganizationMembership from "../components/OrganizationMembership";
import ResourceTable from "../components/ResourceTable";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import formatDate from "../modules/formatDate";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import useToggle from "../shared/react/useToggle";
import ArrowRightIcon from "@mui/icons-material/ArrowRight";
import CreateIcon from "@mui/icons-material/Create";
import DraftsIcon from "@mui/icons-material/Drafts";
import EditIcon from "@mui/icons-material/Edit";
import ReplyIcon from "@mui/icons-material/Reply";
import SendIcon from "@mui/icons-material/Send";
import { Card, CardContent, Fade, Stack, TextField, Typography } from "@mui/material";
import Button from "@mui/material/Button";
import ButtonGroup from "@mui/material/ButtonGroup";
import ClickAwayListener from "@mui/material/ClickAwayListener";
import Grow from "@mui/material/Grow";
import IconButton from "@mui/material/IconButton";
import MenuItem from "@mui/material/MenuItem";
import MenuList from "@mui/material/MenuList";
import Paper from "@mui/material/Paper";
import Popper from "@mui/material/Popper";
import TrapFocus from "@mui/material/Unstable_TrapFocus";
import { useTheme } from "@mui/styles";
import React from "react";

export default function OrganizationMembershipVerificationListPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getList = React.useCallback(() => {
    return api.getOrganizationMembershipVerificationTodo({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);

  const { state: rawListResponse, loading: listLoading } = useAsyncFetch(getList, {
    default: {},
    pickData: true,
  });
  const [updatedListResponses, setUpdatedListResponses] = React.useState({});

  const handleApiCall = React.useCallback(
    (promise) => {
      return promise
        .then((r) =>
          setUpdatedListResponses({ ...updatedListResponses, [r.data.id]: r.data })
        )
        .catch(enqueueErrorSnackbar);
    },
    [enqueueErrorSnackbar, updatedListResponses]
  );

  const listResponse = {
    ...rawListResponse,
    items: (rawListResponse.items || []).map((r) => updatedListResponses[r.id] || r),
  };

  const [notedVerificationId, setNotedVerificationId] = React.useState(null);
  const notedVerification = listResponse.items.find((v) => v.id === notedVerificationId);

  return (
    <>
      <ResourceTable
        page={page}
        perPage={perPage}
        // search={canSearch ? search : undefined}
        // disableSearch={!canSearch}
        order={order}
        orderBy={orderBy}
        title="Verifications"
        listResponse={listResponse}
        listLoading={listLoading}
        tableProps={{ sx: { minWidth: 650 }, size: "small" }}
        onParamsChange={setListQueryParams}
        columns={[
          {
            id: "status",
            label: "Status",
            sortable: true,
            render: (c) => (
              <StatusCell
                verification={c}
                onApiCall={handleApiCall}
                isNoted={c.id === notedVerification?.id}
                onNotesClicked={() =>
                  setNotedVerificationId(c.id === notedVerification?.id ? null : c.id)
                }
              />
            ),
          },
          {
            id: "member",
            label: "Member",
            align: "left",
            render: (c) => <MemberInfo verification={c} onApiCall={handleApiCall} />,
          },
          {
            id: "phone",
            label: "Phone",
            align: "left",
            render: (c) => c.formattedPhone,
          },
          {
            id: "organization",
            label: "Organization",
            align: "left",
            render: (c) => <OrgInfo verification={c} onApiCall={handleApiCall} />,
          },
          {
            id: "created_at",
            label: "Registered",
            align: "left",
            sortable: true,
            render: (c) => formatDate(c.membership.member.createdAt),
          },
        ]}
      />
      <NotesViewer verification={notedVerification} onApiCall={handleApiCall} />
    </>
  );
}

const statusColors = {
  reject: "error.main",
  approve: "success.main",
};
const statusBtnProps = {
  in_progress: { variant: "outlined" },
};

function StatusCell({ verification, isNoted, onNotesClicked, onApiCall }) {
  const handleTransition = React.useCallback(
    (row, option) => {
      onApiCall(
        api.transitionOrganizationMembershipVerification({ id: row.id, event: option })
      );
    },
    [onApiCall]
  );
  return (
    <Stack gap={1}>
      <StatusPicker
        value={verification.status}
        options={verification.availableEvents}
        onOptionSelected={(o) => handleTransition(verification, o)}
      />
      <Button
        variant={isNoted ? "contained" : "outlined"}
        onClick={() => onNotesClicked()}
      >
        Notes
      </Button>
    </Stack>
  );
}

function StatusPicker({ value, options, onClick, onOptionSelected }) {
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
    color: statusColors[value] || "secondary",
    ...statusBtnProps[value],
  };

  return (
    <>
      <ButtonGroup {...bprops} ref={anchorRef}>
        <Button sx={{ display: "flex", flex: 1 }} onClick={onClick}>
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
                      sx={{ textTransform: "capitalize", color: statusColors[option] }}
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

function MemberInfo({ verification, onApiCall }) {
  function handleBegin(e) {
    e.preventDefault();
    onApiCall(
      api
        .beginOrganizationMembershipVerificationMemberOutreach({ id: verification.id })
        .tap((r) => window.open(r.data.frontMemberConversationStatus.webUrl, "_blank"))
    );
  }
  return (
    <Stack gap={1}>
      <AdminLink model={verification.membership.member}>
        {verification.membership.member.name}
      </AdminLink>
      <FrontConvoStatus
        {...verification.frontMemberConversationStatus}
        onBegin={handleBegin}
      />
    </Stack>
  );
}

function OrgInfo({ verification, onApiCall }) {
  function handleBegin(e) {
    e.preventDefault();
    onApiCall(
      api
        .beginOrganizationMembershipVerificationPartnerOutreach({ id: verification.id })
        .tap((r) => window.open(r.data.frontPartnerConversationStatus.webUrl, "_blank"))
    );
  }
  return (
    <Stack gap={1}>
      <OrganizationMembership membership={verification.membership} />
      <FrontConvoStatus
        {...verification.frontPartnerConversationStatus}
        onBegin={handleBegin}
      />
    </Stack>
  );
}

function FrontConvoStatus({
  webUrl,
  waitingOnAdmin,
  initialDraft,
  lastUpdatedAt,
  onBegin,
}) {
  [webUrl, initialDraft, waitingOnAdmin, lastUpdatedAt] = getTestingProps();
  let Icon, text;
  const bprops = { href: webUrl, target: "_blank" };
  if (!webUrl) {
    Icon = CreateIcon;
    text = "Begin";
    bprops.href = bprops.target = null;
    bprops.variant = "contained";
    bprops.color = "primary";
    bprops.onClick = onBegin;
  } else if (initialDraft) {
    Icon = DraftsIcon;
    text = "Draft";
    bprops.variant = "contained";
    bprops.color = "primary";
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
      <Button size="small" {...bprops}>
        <Icon sx={{ marginRight: 1 }} />
        {text}
      </Button>
    </div>
  );
}

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

function NotesViewer({ verification, onApiCall }) {
  const [noteContent, setNoteContent] = React.useState();
  const theme = useTheme();
  function handleNoteSave(e) {
    e.preventDefault();
    onApiCall(
      api.addOrganizationMembershipVerificationNote({
        id: verification.id,
        content: noteContent,
      })
    ).then(() => setNoteContent(""));
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
            }}
          >
            <Stack direction="row" justifyContent="space-between" gap={2}>
              <Stack gap={1} sx={{ flex: 1 }}>
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
                <Button variant="contained" onClick={handleNoteSave}>
                  Save
                </Button>
              </Stack>
            </Stack>
          </Paper>
        </Fade>
      </TrapFocus>
    </React.Fragment>
  );
}
