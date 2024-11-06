import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import Copyable from "../components/Copyable";
import DetailGrid from "../components/DetailGrid";
import InlineEditField from "../components/InlineEditField";
import PaymentAccountRelatedLists from "../components/PaymentAccountRelatedLists";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import { useUser } from "../hooks/user";
import { dayjs, dayjsOrNull } from "../modules/dayConfig";
import createRelativeUrl from "../shared/createRelativeUrl";
import Money from "../shared/react/Money";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import useToggle from "../shared/react/useToggle";
import DeleteIcon from "@mui/icons-material/Delete";
import {
  Divider,
  Typography,
  Switch,
  Button,
  Chip,
  DialogTitle,
  Dialog,
  DialogContent,
  DialogActions,
} from "@mui/material";
import IconButton from "@mui/material/IconButton";
import { makeStyles } from "@mui/styles";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { formatPhoneNumber, formatPhoneNumberIntl } from "react-phone-number-input";
import { useParams } from "react-router-dom";

export default function MemberDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const handleUpdateMember = (member, replaceState) => {
    return api
      .updateMember(member)
      .then((r) => replaceState(r.data))
      .catch(enqueueErrorSnackbar);
  };
  return (
    <>
      <Typography variant="h5" gutterBottom>
        Member Details <ImpersonateButton id={id} />
      </Typography>
      <Divider />
      <ResourceDetail
        resource="member"
        apiGet={api.getMember}
        canEdit
        properties={(model, replaceState) => [
          { label: "ID", value: model.id },
          { label: "Name", value: model.name },
          { label: "Email", value: model.email },
          {
            label: "Phone Number",
            value: formatPhoneNumberIntl("+" + model.phone),
          },
          {
            label: "Verified",
            children: (
              <InlineEditField
                resource="member"
                renderDisplay={
                  model.onboardingVerifiedAt
                    ? dayjs(model.onboardingVerifiedAt).format("lll")
                    : "-"
                }
                initialEditingState={{ id: model.id }}
                renderEdit={(st, set) => {
                  const mem = { ...model, ...st };
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
                onSave={(member) => handleUpdateMember(member, replaceState)}
              />
            ),
          },
          {
            label: "Roles",
            children: model.roles.map((role) => (
              <Chip key={role.id} label={role.label} sx={{ mr: 0.5 }} />
            )),
            hideEmpty: true,
          },
        ]}
      >
        {(model, setModel) => (
          <>
            <DetailGrid
              title="Other Information"
              properties={[
                { label: "Timezone", value: model.timezone },
                { label: "Created At", value: dayjs(model.createdAt) },
                {
                  label: "Deleted At",
                  value: (
                    <InlineSoftDelete
                      id={model.id}
                      name={model.name}
                      phone={formatPhoneNumber("+" + model.phone)}
                      softDeletedAt={model.softDeletedAt}
                      onSoftDelete={(member) => setModel(member)}
                    />
                  ),
                },
              ]}
            />
            <LegalEntity {...model.legalEntity} />
            <MemberProgramEnrollments
              member={model}
              enrollments={model.programEnrollments}
            />
            <OrganizationMemberships memberships={model.organizationMemberships} />
            <Activities activities={model.activities} />
            <Orders orders={model.orders} />
            <Charges charges={model.charges} />
            <BankAccounts bankAccounts={model.bankAccounts} />
            <PaymentAccountRelatedLists paymentAccount={model.paymentAccount} />
            <VendorAccounts vendorAccounts={model.vendorAccounts} />
            <MessagePreferences preferences={model.preferences} />
            <MessageDeliveries messageDeliveries={model.messageDeliveries} />
            <Sessions sessions={model.sessions} />
            <ResetCodes resetCodes={model.resetCodes} />
          </>
        )}
      </ResourceDetail>
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

function MemberProgramEnrollments({ member, enrollments }) {
  return (
    <RelatedList
      title="Program Enrollments"
      headers={["Id", "Program", "Program Active", "Approved At", "Unenrolled At"]}
      rows={enrollments}
      addNewLabel="Enroll in another program"
      addNewLink={createRelativeUrl(`/program-enrollment/new`, {
        memberId: member.id,
        memberLabel: `(${member.id}) ${member.name}`,
      })}
      addNewRole="member"
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        <AdminLink model={row.program}>{row.program.name.en}</AdminLink>,
        <BoolCheckmark>{row.programActive}</BoolCheckmark>,
        dayjsOrNull(row.approvedAt)?.format("lll"),
        dayjsOrNull(row.unenrolledAt)?.format("lll"),
      ]}
    />
  );
}

function OrganizationMemberships({ memberships }) {
  return (
    <RelatedList
      title="Organization Memberships"
      headers={["Id", "Created At", "Organization"]}
      rows={memberships}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        dayjs(row.createdAt).format("lll"),
        row.verifiedOrganization ? (
          <AdminLink model={row.verifiedOrganization}>
            {row.verifiedOrganization.name}
          </AdminLink>
        ) : (
          row.unverifiedOrganizationName
        ),
      ]}
    />
  );
}

function Activities({ activities }) {
  return (
    <RelatedList
      title="Activities"
      headers={["At", "Summary", "Message"]}
      rows={activities}
      keyRowAttr="id"
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
      keyRowAttr="id"
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
          {row.offering.description.en}
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
      headers={["Id", "At", "Discounted Total", "Undiscounted Total", "Opaque Id"]}
      rows={charges}
      toCells={(row) => [
        row.id,
        dayjs(row.createdAt).format("lll"),
        <Money key={3}>{row.discountedSubtotal}</Money>,
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

function MessagePreferences({ preferences }) {
  if (!preferences) {
    return null;
  }
  const { subscriptions, publicUrl } = preferences;
  return (
    <>
      <RelatedList
        title="Message Preferences"
        headers={["Key", "Opted In", "Editable State"]}
        rows={subscriptions}
        keyRowAttr="key"
        toCells={(row) => [
          row.key,
          <BoolCheckmark key={2}>{row.optedIn}</BoolCheckmark>,
          row.editableState,
        ]}
      />
      <Typography sx={{ mt: 2 }}>
        Give this link to the member when they request to change their messaging
        preferences:{" "}
        <Copyable text={publicUrl} inline>
          <SafeExternalLink href={publicUrl}>{publicUrl}</SafeExternalLink>
        </Copyable>
      </Typography>
    </>
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

function VendorAccounts({ vendorAccounts }) {
  return (
    <RelatedList
      title="Vendor Accounts"
      headers={[
        "Id",
        "Created",
        "Vendor",
        "Latest Access Code Magic Link",
        "Latest Access Code",
      ]}
      rows={vendorAccounts}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        dayjs(row.createdAt).format("lll"),
        <AdminLink key="id" model={row.vendor}>
          {row.vendor.name}
        </AdminLink>,
        <SafeExternalLink href={row.latestAccessCodeMagicLink}>
          {row.latestAccessCodeMagicLink}
        </SafeExternalLink>,
        row.latestAccessCode,
      ]}
    />
  );
}

function ImpersonateButton({ id }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { user, setUser } = useUser();
  const { canWrite } = useRoleAccess();
  const classes = useStyles();

  function handleImpersonate() {
    api
      .impersonate({ id })
      .then((r) => setUser(r.data))
      .catch(enqueueErrorSnackbar);
  }
  function handleUnimpersonate() {
    api
      .unimpersonate()
      .then((r) => setUser(r.data))
      .catch(enqueueErrorSnackbar);
  }

  if (!canWrite("impersonate")) {
    return null;
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

function InlineSoftDelete({ id, name, phone, softDeletedAt, onSoftDelete }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const showModal = useToggle(false);
  const handleDelete = () => {
    api
      .softDeleteMember({ id: id })
      .then((r) => {
        onSoftDelete(r.data);
        showModal.turnOff();
      })
      .catch(enqueueErrorSnackbar);
  };
  const { canWrite } = useRoleAccess();
  let display = "-";
  if (canWrite("admin_members")) {
    display = (
      <>
        {"- "}
        <IconButton onClick={() => showModal.turnOn()}>
          <DeleteIcon color="error" />
        </IconButton>
      </>
    );
  }
  return (
    <>
      {softDeletedAt ? dayjs(softDeletedAt).format("lll") : display}
      <Dialog open={showModal.isOn} onClose={showModal.turnOff}>
        <DialogTitle>Confirm Soft Deletion</DialogTitle>
        <DialogContent>
          <Typography sx={{ mt: 1 }} color="error">
            Member deletion CANNOT be undone. Ensure that you know what you are doing
            before continuing.
          </Typography>
          <Typography sx={{ mt: 1 }}>
            "Soft delete" means an account is closed indefinitely but keeps some important
            records attached to the account in case we need to refer to past data. It
            replaces the member's phone and email with unreachable values, preventing any
            further account access.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDelete} variant="contained" color="error" size="small">
            Soft Delete
            <br />
            {name}
            <br />
            {phone}
          </Button>
          <Button
            variant="outlined"
            color="secondary"
            size="small"
            onClick={showModal.turnOff}
          >
            Cancel
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}

const useStyles = makeStyles((theme) => ({
  impersonate: {
    marginLeft: theme.spacing(2),
  },
}));
