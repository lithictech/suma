import api from "../api";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedListTable";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useGlobalStyles from "../hooks/useGlobalStyles";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { Divider, Container, CircularProgress, Typography, Chip } from "@mui/material";
import _ from "lodash";
import React from "react";
import { formatPhoneNumberIntl } from "react-phone-number-input";
import { useParams } from "react-router-dom";

export default function MemberDetailPage() {
  const classes = useGlobalStyles();
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  const getMember = React.useCallback(() => {
    return api
      .getMember({ id: id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: member, loading: memberLoading } = useAsyncFetch(getMember, {
    default: {},
    pickData: true,
  });
  const unavailable = (
    <Typography component="span" color="textSecondary">
      Unavailable
    </Typography>
  );

  return (
    <Container className={classes.root} maxWidth="lg">
      {memberLoading && <CircularProgress />}
      {!_.isEmpty(member) && (
        <div>
          <Typography variant="h5" gutterBottom>
            Member Details
          </Typography>
          <Divider />
          <Typography variant="h6" mt={2} mb={1}>
            Account Information
          </Typography>
          <DetailGrid
            properties={[
              { label: "ID", value: id },
              { label: "Name", value: member.name || unavailable },
              { label: "Email", value: member.email || unavailable },
              {
                label: "Phone Number",
                value: formatPhoneNumberIntl("+" + member.phone) || unavailable,
              },
              {
                label: "Roles",
                children: member.roles.map((role) => (
                  <Chip key={role} label={_.capitalize(role)} />
                )),
                hideEmpty: true,
              },
            ]}
          />
          <Typography variant="h6" mt={2} mb={1}>
            Other Information
          </Typography>
          <DetailGrid
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
          <LegalEntity entity={member.legalEntity} />
          <ActivityList activities={member.activities} />
        </div>
      )}
    </Container>
  );
}

function LegalEntity({ entity }) {
  const { address1, address2, city, stateOrProvince, postalCode, country } =
    entity.address || {};
  return (
    <div>
      <Typography variant="h6" mt={2} mb={1}>
        Legal Entity
      </Typography>
      <DetailGrid
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

function ActivityList({ activities }) {
  if (_.isEmpty(activities)) {
    return null;
  }
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
