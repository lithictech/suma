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
import { Divider, CircularProgress, Typography, Chip } from "@mui/material";
import Button from "@mui/material/Button";
import { makeStyles } from "@mui/styles";
import _ from "lodash";
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
      {!_.isEmpty(member) && (
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
                  <Chip key={role} label={_.capitalize(role)} sx={{ mr: 0.5 }} />
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
  if (_.isEmpty(address)) {
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
