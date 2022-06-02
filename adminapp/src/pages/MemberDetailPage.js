import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useGlobalStyles from "../hooks/useGlobalStyles";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import {
  Divider,
  Container,
  Grid,
  CircularProgress,
  Typography,
  Chip,
} from "@mui/material";
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
          <Grid container spacing={2}>
            <Grid item sx={{ width: "180px" }}>
              <CustomTypography label>ID:</CustomTypography>
              <CustomTypography label>Name:</CustomTypography>
              <CustomTypography label>Email:</CustomTypography>
              <CustomTypography label>Phone Number:</CustomTypography>
              {!_.isEmpty(member.roles) && (
                <CustomTypography label>Roles:</CustomTypography>
              )}
            </Grid>
            <Grid item>
              <CustomTypography>{id}</CustomTypography>
              <CustomTypography>{member.name || unavailable}</CustomTypography>
              <CustomTypography>{member.email || unavailable}</CustomTypography>
              <CustomTypography>
                {formatPhoneNumberIntl("+" + member.phone) || unavailable}
              </CustomTypography>
              {!_.isEmpty(member.roles) &&
                member.roles.map((role) => {
                  return <Chip key={role} label={_.capitalize(role)} />;
                })}
            </Grid>
          </Grid>
          <Typography variant="h6" mt={2} mb={1}>
            Other Information
          </Typography>
          <Grid container spacing={2}>
            <Grid item sx={{ width: "180px" }}>
              <CustomTypography label>Timezone:</CustomTypography>
              <CustomTypography label>Account Created:</CustomTypography>
            </Grid>
            <Grid item>
              <CustomTypography>{member.timezone}</CustomTypography>
              <CustomTypography>{dayjs(member.createdAt).format("lll")}</CustomTypography>
              {member.softDeletedAt && (
                <CustomTypography>
                  <strong>
                    Account soft deleted on {dayjs(member.createdAt).format("lll")}
                  </strong>
                </CustomTypography>
              )}
            </Grid>
          </Grid>
          <LegalEntity entity={member.legalEntity} />
          <JourneyList journeys={member.journeys} />
        </div>
      )}
    </Container>
  );
}

function LegalEntity({ entity }) {
  const { address1, address2, city, stateOrProvince, postalCode, country } =
    entity.address;
  return (
    <div>
      <Typography variant="h6" mt={2} mb={1}>
        Legal Entity
      </Typography>
      <Grid container spacing={2}>
        <Grid item sx={{ width: "180px" }}>
          <CustomTypography label>Address:</CustomTypography>
          <CustomTypography label>City:</CustomTypography>
          <CustomTypography label>State:</CustomTypography>
          <CustomTypography label>Postal Code:</CustomTypography>
          <CustomTypography label>Country:</CustomTypography>
        </Grid>
        <Grid item>
          <CustomTypography>{address1 + " " + address2}</CustomTypography>
          <CustomTypography>{city}</CustomTypography>
          <CustomTypography>{stateOrProvince}</CustomTypography>
          <CustomTypography>{postalCode}</CustomTypography>
          <CustomTypography>{country}</CustomTypography>
        </Grid>
      </Grid>
    </div>
  );
}

function JourneyList({ journeys }) {
  if (_.isEmpty(journeys)) {
    return null;
  }
  return (
    <>
      <Typography variant="h6" mt={2} mb={1}>
        Journey
      </Typography>
      {journeys.map((j) => {
        return (
          <div key={j.id}>
            {journeys.length > 1 && <Divider variant="middle" sx={{ my: 1 }} />}
            <Grid key={j.id} container spacing={2}>
              <Grid item>
                <Typography variant="h6">{dayjs(j.createdAt).format("lll")}</Typography>
                <CustomTypography color="textSecondary">
                  <Chip component="span" color="primary" label={_.capitalize(j.name)} />{" "}
                  {j.message}
                </CustomTypography>
              </Grid>
            </Grid>
          </div>
        );
      })}
    </>
  );
}

function CustomTypography({ children, label, ...props }) {
  if (_.isEmpty(children)) {
    return;
  }
  const customProps = label
    ? { variant: "body1", color: "textSecondary", align: "right" }
    : { variant: "body1" };
  return (
    <Typography {...props} {...customProps} gutterBottom>
      {children}
    </Typography>
  );
}
