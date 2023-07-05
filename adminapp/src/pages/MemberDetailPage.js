import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import DetailGrid from "../components/DetailGrid";
import PaymentAccountRelatedLists from "../components/PaymentAccountRelatedLists";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { useUser } from "../hooks/user";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import ArrowDropDownIcon from "@mui/icons-material/ArrowDropDown";
import KeyboardArrowDownIcon from "@mui/icons-material/KeyboardArrowDown";
import LoadingButton from "@mui/lab/LoadingButton";
import {
  Divider,
  CircularProgress,
  Typography,
  Chip,
  ButtonGroup,
  Popper,
  Paper,
  ClickAwayListener,
  MenuList,
  MenuItem,
  Grow,
  FormControl,
  InputLabel,
  Select,
  Menu,
} from "@mui/material";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import { alpha, styled } from "@mui/material/styles";
import { makeStyles } from "@mui/styles";
import capitalize from "lodash/capitalize";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { formatPhoneNumberIntl } from "react-phone-number-input";
import { useParams } from "react-router-dom";

export default function MemberDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getMember = React.useCallback(() => {
    return api
      .getMember({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: member, loading: memberLoading } = useAsyncFetch(getMember, {
    default: {},
    pickData: true,
  });

  return (
    <>
      {memberLoading && <CircularProgress />}
      {!isEmpty(member) && (
        <div>
          <Typography variant="h5" gutterBottom>
            Member Details <ImpersonateButton id={id} />
          </Typography>
          <Divider />
          <DetailGrid
            title="Account Information"
            properties={[
              { label: "ID", value: id },
              { label: "Name", value: member.name },
              { label: "Email", value: member.email },
              {
                label: "Phone Number",
                value: formatPhoneNumberIntl("+" + member.phone),
              },
              {
                label: "Roles",
                children: member.roles.map((role) => (
                  <Chip key={role} label={capitalize(role)} sx={{ mr: 0.5 }} />
                )),
                hideEmpty: true,
              },
            ]}
          />
          <DetailGrid
            title="Other Information"
            properties={[
              { label: "Timezone", value: member.timezone },
              { label: "Created At", value: dayjs(member.createdAt) },
              {
                label: "Deleted At",
                value: member.softDeletedAt && dayjs(member.softDeletedAt),
                hideEmpty: true,
              },
            ]}
          />
          <LegalEntity {...member.legalEntity} />
          <EligibilityConstraints
            constraints={member.eligibilityConstraints}
            memberId={id}
          />
          <Activities activities={member.activities} />
          <Orders orders={member.orders} />
          <Sessions sessions={member.sessions} />
          <ResetCodes resetCodes={member.resetCodes} />
          <Charges charges={member.charges} />
          <BankAccounts bankAccounts={member.bankAccounts} />
          <PaymentAccountRelatedLists paymentAccount={member.paymentAccount} />
        </div>
      )}
    </>
  );
}

function LegalEntity({ address }) {
  if (isEmpty(address)) {
    return null;
  }
  const { address1, address2, city, stateOrProvince, postalCode, country } =
    address || {};
  return (
    <div>
      <DetailGrid
        title="Legal Entity"
        properties={[
          {
            label: "Street Address",
            value: [address1, address2].filter(Boolean).join(" "),
          },
          { label: "City", value: city },
          { label: "State", value: stateOrProvince },
          { label: "Postal Code", value: postalCode },
          { label: "Country", value: country },
        ]}
      />
    </div>
  );
}

function EligibilityConstraints({ constraints, memberId }) {
  const [memberConstraints, setMemberConstraints] = React.useState(constraints);
  const { state: allEligibilityConstraints, loading: eligibilityConstraintsLoading } =
    useAsyncFetch(api.getEligibilityConstraints, {
      pickData: true,
    });
  if (eligibilityConstraintsLoading) {
    return "loading";
  }
  const allowedEligibilityConstraintStatuses = ["verified", "pending", "rejected"];
  return (
    <React.Fragment>
      <Typography variant="h6">Member Eligiblity Constraints</Typography>
      {memberConstraints.map((c) => (
        <Constraint
          key={c}
          allowedStatuses={allowedEligibilityConstraintStatuses}
          memberId={memberId}
          onChangeConstraint={(constraints) => setMemberConstraints(constraints)}
          {...c}
        />
      ))}
    </React.Fragment>
  );
}

function Constraint({
  constraintName,
  constraintId,
  status,
  allowedStatuses,
  memberId,
  onChangeConstraint,
}) {
  const [anchorEl, setAnchorEl] = React.useState(null);
  const open = Boolean(anchorEl);
  const handleClick = (event) => {
    setAnchorEl(event.currentTarget);
  };
  const handleSelectStatus = (e, chosenStatus) => {
    api
      .changeMemberEligibility({
        id: memberId,
        values: [{ constraintId: constraintId, status: chosenStatus }],
      })
      .then(api.pickData)
      .then((response) => onChangeConstraint(response.eligibilityConstraints));
    handleClose();
  };

  const handleClose = () => {
    setAnchorEl(null);
  };
  return (
    <div>
      <Typography variant="text">{constraintName}:</Typography>
      <Button
        id="demo-customized-button"
        aria-controls={open ? constraintId : undefined}
        aria-haspopup="true"
        aria-expanded={open ? "true" : undefined}
        variant="contained"
        disableElevation
        onClick={handleClick}
        endIcon={<KeyboardArrowDownIcon />}
      >
        {status}
      </Button>
      <StyledEligibilityConstraintMenu
        id={constraintId}
        MenuListProps={{
          "aria-labelledby": "demo-customized-button",
        }}
        anchorEl={anchorEl}
        open={open}
        onClose={handleClose}
      >
        {allowedStatuses.map((allowedStatus) => (
          <MenuItem
            key={allowedStatus}
            onClick={(e) => handleSelectStatus(e, allowedStatus)}
            disableRipple
            selected={allowedStatus === status}
          >
            {allowedStatus}
          </MenuItem>
        ))}
      </StyledEligibilityConstraintMenu>
    </div>
  );
}

function Activities({ activities }) {
  return (
    <RelatedList
      title="Activities"
      headers={["At", "Summary", "Message"]}
      rows={activities}
      toCells={(row) => [
        dayjs(row.createdAt).format("lll"),
        row.summary,
        <span key="msg">
          {row.messageName} / <code>{JSON.stringify(row.messageVars)}</code>
        </span>,
      ]}
    />
  );
}

function ResetCodes({ resetCodes }) {
  return (
    <RelatedList
      title="Login Codes"
      headers={["Sent", "Expires", "Token", "Used"]}
      rows={resetCodes}
      toCells={(row) => [
        dayjs(row.createdAt).format("lll"),
        dayjs(row.expireAt).format("lll"),
        row.token,
        <BoolCheckmark key={4}>{row.used}</BoolCheckmark>,
      ]}
    />
  );
}

function Sessions({ sessions }) {
  return (
    <RelatedList
      title="Sessions"
      headers={["Started", "IP", "User Agent"]}
      rows={sessions}
      toCells={(row) => [
        dayjs(row.createdAt).format("lll"),
        <SafeExternalLink key={2} href={row.ipLookupLink}>
          {row.peerIp}
        </SafeExternalLink>,
        row.userAgent,
      ]}
    />
  );
}

function Orders({ orders }) {
  return (
    <RelatedList
      title="Orders"
      rows={orders}
      headers={["Id", "Created At", "Items", "Offering", "Status"]}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        dayjs(row.createdAt).format("lll"),
        row.totalItemCount,
        <AdminLink key="off" model={row.offering}>
          {row.offering.description}
        </AdminLink>,
        row.statusLabel,
      ]}
    />
  );
}

function Charges({ charges }) {
  return (
    <RelatedList
      title="Charges"
      headers={["Id", "At", "Undiscounted Total", "Opaque Id"]}
      rows={charges}
      toCells={(row) => [
        row.id,
        dayjs(row.createdAt).format("lll"),
        <Money key={3}>{row.undiscountedSubtotal}</Money>,
        row.opaqueId,
      ]}
    />
  );
}

function BankAccounts({ bankAccounts }) {
  return (
    <RelatedList
      title="Bank Accounts"
      headers={["Id", "Name", "Added", "Deleted"]}
      rows={bankAccounts}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        row.adminLabel,
        dayjs(row.createdAt).format("lll"),
        row.softDeletedAt ? dayjs(row.softDeletedAt).format("lll") : "",
      ]}
    />
  );
}

function ImpersonateButton({ id }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { user, setUser } = useUser();
  const classes = useStyles();

  function handleImpersonate() {
    api
      .impersonate({ id })
      .then((r) => setUser(r.data))
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }
  function handleUnimpersonate() {
    api
      .unimpersonate()
      .then((r) => setUser(r.data))
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }
  if (user.impersonating) {
    return (
      <Button
        className={classes.impersonate}
        onClick={handleUnimpersonate}
        variant="contained"
        color="warning"
        size="small"
      >
        Unimpersonate {user.impersonating.name || user.impersonating.phone}
      </Button>
    );
  }
  if (id === user.id) {
    return null; // don't impersonate yourself
  }
  return (
    <Button
      className={classes.impersonate}
      onClick={handleImpersonate}
      variant="outlined"
      color="warning"
      size="small"
    >
      Impersonate
    </Button>
  );
}

const useStyles = makeStyles((theme) => ({
  impersonate: {
    marginLeft: theme.spacing(2),
  },
}));

const StyledEligibilityConstraintMenu = styled((props) => (
  <Menu
    elevation={0}
    anchorOrigin={{
      vertical: "bottom",
      horizontal: "right",
    }}
    transformOrigin={{
      vertical: "top",
      horizontal: "right",
    }}
    {...props}
  />
))(({ theme }) => ({
  "& .MuiPaper-root": {
    borderRadius: 6,
    marginTop: theme.spacing(1),
    minWidth: 180,
    color: theme.palette.mode === "light" ? "rgb(55, 65, 81)" : theme.palette.grey[300],
    boxShadow:
      "rgb(255, 255, 255) 0px 0px 0px 0px, rgba(0, 0, 0, 0.05) 0px 0px 0px 1px, rgba(0, 0, 0, 0.1) 0px 10px 15px -3px, rgba(0, 0, 0, 0.05) 0px 4px 6px -2px",
    "& .MuiMenu-list": {
      padding: "4px 0",
    },
    "& .MuiMenuItem-root": {
      "& .MuiSvgIcon-root": {
        fontSize: 18,
        color: theme.palette.text.secondary,
        marginRight: theme.spacing(1.5),
      },
      "&:active": {
        backgroundColor: theme.palette.primary.main,
      },
    },
  },
}));
