import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import BoolCheckmark from "../components/BoolCheckmark";
import Copyable from "../components/Copyable";
import DetailGrid from "../components/DetailGrid";
import InlineEditField from "../components/InlineEditField";
import OrganizationMembership from "../components/OrganizationMembership";
import PaymentAccountRelatedLists from "../components/PaymentAccountRelatedLists";
import ProgramEnrollmentRelatedList from "../components/ProgramEnrollmentRelatedList";
import RelatedList from "../components/RelatedList";
import ResourceDetail, { ResourceSummary } from "../components/ResourceDetail";
import ResponsiveStack from "../components/ResponsiveStack";
import SupportNoteModal from "../components/SupportNoteModal";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import { useUser } from "../hooks/user";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import createRelativeUrl from "../shared/createRelativeUrl";
import Money from "../shared/react/Money";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import useToggle from "../shared/react/useToggle";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import {
  Typography,
  Switch,
  Button,
  Chip,
  DialogTitle,
  Dialog,
  DialogContent,
  DialogActions,
  Stack,
} from "@mui/material";
import IconButton from "@mui/material/IconButton";
import TableCell from "@mui/material/TableCell";
import { makeStyles } from "@mui/styles";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { formatPhoneNumber, formatPhoneNumberIntl } from "react-phone-number-input";

export default function MemberDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const handleUpdateMember = (member, replaceState) => {
    return api
      .updateMember(member)
      .then((r) => replaceState(r.data))
      .catch(enqueueErrorSnackbar);
  };
  return (
    <>
      <ResourceDetail
        resource="member"
        apiGet={api.getMember}
        canEdit
        properties={(model, replaceState) => [
          {
            tableCells: (props) => (
              <TableCell colSpan={2} {...props}>
                <ImpersonateButton id={model.id} sx={{ mb: 1 }} />
              </TableCell>
            ),
          },
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
                renderDisplay={formatDate(model.onboardingVerifiedAt)}
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
        {(model, setModel) => [
          <ResourceSummary>
            <DetailGrid
              title="Other Information"
              properties={[
                {
                  label: "Preferred Language",
                  value: model.preferences.preferredLanguageName,
                },
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
                model.previousEmails.length > 0 && {
                  label: "Previous Emails",
                  value: model.previousEmails.join(", "),
                },
                model.previousPhones.length > 0 && {
                  label: "Previous Phones",
                  value: model.previousPhones.join(", "),
                },
              ]}
            />
          </ResourceSummary>,
          <ResourceSummary>
            <LegalEntity {...model.legalEntity} />
          </ResourceSummary>,
          model.referral && (
            <ResourceSummary>
              <DetailGrid
                title="Referral"
                properties={[
                  { label: "ID", value: model.referral.id },
                  { label: "Created At", value: dayjs(model.referral.createdAt) },
                  { label: "Source", value: model.referral.source },
                  { label: "Campaign", value: model.referral.campaign },
                  { label: "Medium", value: model.referral.medium },
                ]}
              />
            </ResourceSummary>
          ),
          <Notes notes={model.notes} model={model} setModel={setModel} />,
          <OrganizationMemberships
            memberships={model.organizationMemberships}
            model={model}
          />,
          <ProgramEnrollmentRelatedList
            model={model}
            resource="member"
            enrollments={model.directProgramEnrollments}
          />,
          <EnrollmentExclusions model={model} />,
          <Activities activities={model.activities} />,
          <Orders orders={model.orders} />,
          <MobilityTrips mobilityTrips={model.mobilityTrips} />,
          <Charges charges={model.charges} />,
          <PaymentInstruments instruments={model.paymentInstruments} />,
          <MessagePreferences preferences={model.preferences} />,
          <VendorAccounts vendorAccounts={model.vendorAccounts} />,
          <MemberContacts memberContacts={model.memberContacts} />,
          <MessageDeliveries messageDeliveries={model.messageDeliveries} />,
          <Sessions sessions={model.sessions} />,
          <ResetCodes resetCodes={model.resetCodes} />,
          <RelatedList
            title="Marketing Lists"
            headers={["Id", "Label"]}
            rows={model.marketingLists}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink model={row} />,
              <AdminLink model={row}>{row.label}</AdminLink>,
            ]}
          />,
          <RelatedList
            title="Marketing SMS Dispatches"
            headers={["Id", "Broadcast", "Status", "Sent At", "Error"]}
            rows={model.marketingSmsDispatches}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink model={row} />,
              <AdminLink model={row.smsBroadcast}>{row.smsBroadcast.label}</AdminLink>,
              row.status,
              formatDate(row.sentAt),
              row.lastError,
            ]}
          />,
          <PaymentAccountRelatedLists paymentAccount={model.paymentAccount} />,
          <AuditActivityList activities={model.auditActivities} />,
        ]}
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

function EnrollmentExclusions({ model }) {
  return (
    <RelatedList
      title="Enrollment Exclusions"
      addNewLabel="Add Exclusion"
      addNewLink={createRelativeUrl(`/program-enrollment-exclusion/new`, {
        enrolleeId: model.id,
        enrolleeLabel: `(${model.id}) ${model.name}`,
        enrolleeType: "member",
      })}
      addNewRole="programEnrollmentExclusion"
      rows={model.programEnrollmentExclusions}
      headers={["Id", "Program"]}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        <AdminLink key="program" model={row.program}>
          {row.program.name.en}
        </AdminLink>,
      ]}
    />
  );
}

function OrganizationMemberships({ memberships, model }) {
  return (
    <RelatedList
      title="Organization Memberships"
      headers={["Id", "Created At", "Organization"]}
      rows={memberships}
      addNewLabel="Create another membership"
      addNewLink={createRelativeUrl(`/membership/new`, {
        memberId: model.id,
        memberLabel: `(${model.id}) ${model.name || "-"}`,
      })}
      addNewRole="organizationMembership"
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        formatDate(row.createdAt),
        <OrganizationMembership membership={row} detailed />,
      ]}
    />
  );
}

function Notes({ notes, model, setModel }) {
  const modalToggle = useToggle();

  const [scratchNote, setScratchNote] = React.useState({});

  function handleNoteSubmitted(r) {
    setModel(r.data);
    modalToggle.turnOff();
  }

  function handleNewClick() {
    setScratchNote({});
    modalToggle.turnOn();
  }

  function handleEditClick(row) {
    setScratchNote(row);
    modalToggle.turnOn();
  }

  return (
    <>
      <SupportNoteModal
        toggle={modalToggle}
        note={scratchNote}
        setNote={setScratchNote}
        apiCreate={api.createMemberNote}
        apiUpdate={api.updateMemberNote}
        apiParams={{ id: model.id }}
        onSubmitted={handleNoteSubmitted}
      />
      <RelatedList
        title="Notes"
        headers={["Id", "Content", "Author", "At"]}
        rows={notes}
        addNewLabel="Add note"
        onAddNewClick={handleNewClick}
        addNewRole="member"
        keyRowAttr="id"
        toCells={(row) => [
          row.id,
          <Stack direction="horizontal" gap={0.5} alignItems="center">
            <IconButton
              size="small"
              sx={{ marginRight: 1 }}
              onClick={() => handleEditClick(row)}
            >
              <EditIcon />
            </IconButton>
            <div dangerouslySetInnerHTML={{ __html: row.contentHtml }} />
          </Stack>,
          row.author && (
            <AdminLink key="id" model={row.author}>
              {row.author.name}
            </AdminLink>
          ),
          formatDate(row.authoredAt),
        ]}
      />
    </>
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
        formatDate(row.createdAt),
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
      headers={["Sent", "Expires", "Token", "Used", "Delivery"]}
      rows={resetCodes}
      keyRowAttr="id"
      toCells={(row) => [
        formatDate(row.createdAt),
        formatDate(row.expireAt),
        row.token,
        <BoolCheckmark key="used">{row.used}</BoolCheckmark>,
        row.messageDelivery ? <AdminLink model={row.messageDelivery} /> : "(not sent)",
      ]}
    />
  );
}

function Sessions({ sessions }) {
  return (
    <RelatedList
      title="Sessions"
      headers={["Started", "IP", "User Agent"]}
      keyRowAttr="id"
      rows={sessions}
      toCells={(row) => [
        formatDate(row.createdAt),
        <SafeExternalLink key="ip" href={row.ipLookupLink}>
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
        formatDate(row.createdAt),
        row.totalItemCount,
        <AdminLink key="off" model={row.offering}>
          {row.offering.description.en}
        </AdminLink>,
        row.statusLabel,
      ]}
    />
  );
}

function MobilityTrips({ mobilityTrips }) {
  return (
    <RelatedList
      title="Trips"
      rows={mobilityTrips}
      headers={["Id", "Began At", "Ended At", "Service", "Rate"]}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        formatDate(row.beganAt),
        formatDate(row.endedAt),
        <AdminLink key="vs" model={row.vendorService}>
          {row.vendorService.internalName}
        </AdminLink>,
        <AdminLink key="r" model={row.vendorServiceRate}>
          {row.vendorServiceRate.internalName}
        </AdminLink>,
      ]}
    />
  );
}

function Charges({ charges }) {
  return (
    <RelatedList
      title="Charges"
      headers={["Id", "At", "Discounted Total", "Undiscounted Total", "Opaque Id"]}
      keyRowAttr="id"
      rows={charges}
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        formatDate(row.createdAt),
        <Money key="disc">{row.discountedSubtotal}</Money>,
        <Money key="undisc">{row.undiscountedSubtotal}</Money>,
        row.opaqueId,
      ]}
    />
  );
}

function PaymentInstruments({ instruments }) {
  return (
    <RelatedList
      title="Payment Methods"
      headers={["Id", "Type", "Name", "Status"]}
      rows={instruments}
      getKey={(r) => `${r.id}-${r.paymentMethodType}`}
      toCells={(row) => [
        <AdminLink key="id" model={row}>
          {row.instrumentId}
        </AdminLink>,
        row.paymentMethodType,
        row.name,
        row.status,
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
    <ResponsiveStack>
      <RelatedList
        title="Message Preferences"
        cardProps={{ sx: { flex: 1 } }}
        headers={["Key", "Opted In", "Editable State"]}
        rows={subscriptions}
        keyRowAttr="key"
        toCells={(row) => [
          row.key,
          <BoolCheckmark key="optedin">{row.optedIn}</BoolCheckmark>,
          row.editableState,
        ]}
      />
      <DetailGrid
        title="Message Preferences"
        cardProps={{ sx: { flex: 1 } }}
        properties={[
          {
            label: "SMS Undeliverable",
            value: preferences.smsUndeliverableAt
              ? `Yes (set ${dayjs(preferences.smsUndeliverableAt).format("l")})`
              : "No",
          },
        ]}
        footer={
          <Typography sx={{ mt: 2 }}>
            Give this link to the member when they request to change their messaging
            preferences:{" "}
            <Copyable text={publicUrl} inline>
              <SafeExternalLink href={publicUrl}>{publicUrl}</SafeExternalLink>
            </Copyable>
          </Typography>
        }
      />
    </ResponsiveStack>
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
        formatDate(row.createdAt),
        formatDate(row.sentAt, { default: "<unsent>" }),
        row.template,
        row.formattedTo,
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
        formatDate(row.createdAt),
        <AdminLink key="vendor" model={row.vendor}>
          {row.vendor.name}
        </AdminLink>,
        <SafeExternalLink key="link" href={row.latestAccessCodeMagicLink}>
          {row.latestAccessCodeMagicLink}
        </SafeExternalLink>,
        row.latestAccessCode,
      ]}
    />
  );
}

function MemberContacts({ memberContacts }) {
  return (
    <RelatedList
      title="Member Contacts"
      headers={["Id", "Address"]}
      rows={memberContacts}
      keyRowAttr="id"
      toCells={(row) => [<AdminLink key="id" model={row} />, row.formattedAddress]}
    />
  );
}

function ImpersonateButton({ id, ...rest }) {
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
        {...rest}
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
      {...rest}
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
      {formatDate(softDeletedAt, { default: display })}
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
