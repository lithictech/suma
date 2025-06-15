import api from "../api";
import AdminLink from "../components/AdminLink";
import OrganizationMembership from "../components/OrganizationMembership";
import ResourceList from "../components/ResourceList";
import ResourceTable from "../components/ResourceTable";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import formatDate from "../modules/formatDate";
import pluralize from "../modules/pluralize";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import useToggle from "../shared/react/useToggle";
import ArrowRightIcon from "@mui/icons-material/ArrowRight";
import Button from "@mui/material/Button";
import ButtonGroup from "@mui/material/ButtonGroup";
import ClickAwayListener from "@mui/material/ClickAwayListener";
import Grow from "@mui/material/Grow";
import MenuItem from "@mui/material/MenuItem";
import MenuList from "@mui/material/MenuList";
import Paper from "@mui/material/Paper";
import Popper from "@mui/material/Popper";
import startCase from "lodash/startCase";
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

  const handleTransition = React.useCallback(
    (row, option) => {
      api
        .transitionOrganizationMembershipVerification({ id: row.id, event: option })
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

  return (
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
          // render: (c) => <Chip color="muted" label={c.status} />,
          render: (c) => (
            <SplitButton
              color="secondary"
              size="small"
              variant="contained"
              value={c.status}
              options={c.availableEvents}
              onOptionSelected={(o) => handleTransition(c, o)}
            />
          ),
        },
        {
          id: "member",
          label: "Member",
          align: "left",
          render: (c) => (
            <AdminLink model={c.membership.member}>{c.membership.member.name}</AdminLink>
          ),
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
          render: (c) => <OrganizationMembership membership={c.membership} />,
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
  );
}

const statusStyles = {
  reject: { color: "error.main" },
  approve: { color: "success.main" },
};

function SplitButton({ value, options, onClick, onOptionSelected, ...rest }) {
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

  return (
    <>
      <ButtonGroup {...rest} ref={anchorRef}>
        <Button onClick={onClick}>{value}</Button>
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
        {({ TransitionProps, placement }) => (
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
                      sx={{ textTransform: "capitalize", ...statusStyles[option] }}
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
