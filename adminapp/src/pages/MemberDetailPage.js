import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import DetailGrid from "../components/DetailGrid";
import InlineEditField from "../components/InlineEditField";
import PaymentAccountRelatedLists from "../components/PaymentAccountRelatedLists";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { useUser } from "../hooks/user";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import CancelIcon from "@mui/icons-material/Cancel";
import EditIcon from "@mui/icons-material/Edit";
import SaveIcon from "@mui/icons-material/Save";
import {
  Divider,
  CircularProgress,
  Typography,
  Chip,
  MenuItem,
  Select,
  Switch,
} from "@mui/material";
import Button from "@mui/material/Button";
import IconButton from "@mui/material/IconButton";
import { makeStyles } from "@mui/styles";
import _ from "lodash";
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
    return api.getMember({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const {
    state: member,
    loading: memberLoading,
    replaceState: replaceMember,
  } = useAsyncFetch(getMember, {
    default: {},
    pickData: true,
  });

  function updateMember(m) {
    return api
      .updateMember(m)
      .then((r) => replaceMember(r.data))
      .catch((e) => enqueueErrorSnackbar(e));
  }

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
                label: "Verified",
                children: (
                  <InlineEditField
                    renderDisplay={
                      member.onboardingVerifiedAt
                        ? dayjs(member.onboardingVerifiedAt).format("lll")
                        : "-"
                    }
                    initialEditingState={{ id: member.id }}
                    renderEdit={(st, set) => {
                      const mem = { ...member, ...st };
                      return (
                        <Switch
                          checked={mem.onboardingVerified}
                          onChange={(e) =>
                            set({
                              ...st,
                              onboardingVerified: e.target.checked,
                            })
                          }
                        ></Switch>
                      );
                    }}
                    onSave={updateMember}
                  />
                ),
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
            memberConstraints={member.eligibilityConstraints}
            memberId={id}
            replaceMemberData={replaceMember}
          />
          <Activities activities={member.activities} />
          <Orders orders={member.orders} />
          <Sessions sessions={member.sessions} />
          <ResetCodes resetCodes={member.resetCodes} />
          <Charges charges={member.charges} />
          <BankAccounts bankAccounts={member.bankAccounts} />
          <PaymentAccountRelatedLists paymentAccount={member.paymentAccount} />
          <MessageDeliveries messageDeliveries={member.messageDeliveries} />
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

function EligibilityConstraints({ memberConstraints, memberId, replaceMemberData }) {
  const [editing, setEditing] = React.useState(false);
  const [updatedConstraints, setUpdatedConstraints] = React.useState([]);
  const [newConstraint, setNewConstraint] = React.useState({});
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const { state: eligibilityConstraints, loading: eligibilityConstraintsLoading } =
    useAsyncFetch(api.getEligibilityConstraints, {
      pickData: true,
    });

  function startEditing() {
    setEditing(true);
    setUpdatedConstraints(memberConstraints);
    setNewConstraint({
      status: "pending",
      constraintId: eligibilityConstraints[0]?.id,
    });
  }

  if (!editing) {
    const properties = [];
    if (_.isEmpty(memberConstraints)) {
      properties.push({
        label: "*",
        value:
          "Member has no constraints. They can access any goods and services that are unconstrained.",
      });
    } else {
      memberConstraints.forEach(({ status, constraint }) =>
        properties.push({
          label: constraint.name,
          value: (
            <Typography variant="span" sx={{ lineHeight: "2.5!important" }}>
              {status}
            </Typography>
          ),
        })
      );
    }
    return (
      <div>
        <DetailGrid
          title={
            <>
              Eligibility Constraints
              <IconButton onClick={startEditing}>
                <EditIcon color="info" />
              </IconButton>
            </>
          }
          properties={properties}
        />
      </div>
    );
  }

  if (eligibilityConstraintsLoading) {
    return "Loading...";
  }

  function discardChanges() {
    setUpdatedConstraints([]);
    setEditing(false);
  }

  function saveChanges() {
    const values = updatedConstraints.map((c) => ({
      constraintId: c.constraint.id,
      status: c.status,
    }));
    if (newConstraint.constraintId) {
      values.push(newConstraint);
    }
    api
      .changeMemberEligibility({
        id: memberId,
        values,
      })
      .then((r) => {
        replaceMemberData(r.data);
        setEditing(false);
      })
      .catch(enqueueErrorSnackbar);
  }

  function modifyConstraint(index, status) {
    const newConstraints = [...updatedConstraints];
    newConstraints[index] = { ...newConstraints[index], status };
    setUpdatedConstraints(newConstraints);
  }

  const properties = updatedConstraints.map((c, idx) => ({
    label: c.constraint.name,
    children: (
      <ConstraintStatus
        activeStatus={c.status}
        statuses={eligibilityConstraints.statuses}
        onChange={(e) => modifyConstraint(idx, e.target.value)}
      />
    ),
  }));

  const existingConstraintIds = memberConstraints.map((c) => c.constraint.id);
  const availableConstraints = eligibilityConstraints.items.filter(
    (c) => !existingConstraintIds.includes(c.id)
  );
  if (!_.isEmpty(availableConstraints)) {
    properties.push({
      label: "Add Constraint",
      children: (
        <div>
          <Select
            value={newConstraint.constraintId || ""}
            onChange={(e) =>
              setNewConstraint({ ...newConstraint, constraintId: Number(e.target.value) })
            }
          >
            {availableConstraints.map((c) => (
              <MenuItem key={c.id} value={c.id}>
                {c.name}
              </MenuItem>
            ))}
          </Select>
        </div>
      ),
    });
  }
  return (
    <div>
      <DetailGrid
        title={
          <>
            Eligibility Constraints
            <IconButton onClick={saveChanges}>
              <SaveIcon color="success" />
            </IconButton>
            <IconButton onClick={discardChanges}>
              <CancelIcon color="error" />
            </IconButton>
          </>
        }
        properties={properties}
      />
    </div>
  );
}

function ConstraintStatus({ activeStatus, statuses, onChange }) {
  return (
    <div>
      <Select value={activeStatus} onChange={onChange} size="small">
        {statuses.map((status) => (
          <MenuItem key={status} value={status}>
            {status}
          </MenuItem>
        ))}
      </Select>
    </div>
  );
}

function Activities({ activities }) {
  return (
    <RelatedList
      title="Activities"
      headers={["At", "Summary", "Message"]}
      rows={activities}
      getKey={(row) => row.id}
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

function MessageDeliveries({ messageDeliveries }) {
  return (
    <RelatedList
      title="Message Deliveries"
      headers={["Id", "Created", "Sent", "Template", "To"]}
      rows={messageDeliveries}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        dayjs(row.createdAt).format("lll"),
        row.sentAt ? dayjs(row.sentAt).format("lll") : "<unsent>",
        row.template,
        row.to,
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
      .catch((e) => enqueueErrorSnackbar(e));
  }
  function handleUnimpersonate() {
    api
      .unimpersonate()
      .then((r) => setUser(r.data))
      .catch((e) => enqueueErrorSnackbar(e));
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
