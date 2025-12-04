import api from "../api";
import BackTo from "../components/BackTo";
import DetailGrid from "../components/DetailGrid";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import elementJoin from "../modules/elementJoin";
import { resourceViewRoute } from "../modules/resourceRoutes";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { Button, CircularProgress, Stack, Typography } from "@mui/material";
import React from "react";
import { useNavigate, useParams } from "react-router-dom";

export default function MarketingSmsBroadcastSendPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { isBusy, busy, notBusy } = useBusy();
  const navigate = useNavigate();
  const { id } = useParams();
  const getMarketingSmsBroadcastReview = React.useCallback(() => {
    return api.getMarketingSmsBroadcastReview({ id }).catch(enqueueErrorSnackbar);
  }, [enqueueErrorSnackbar, id]);
  const { state, loading } = useAsyncFetch(getMarketingSmsBroadcastReview, {
    default: {},
    pickData: true,
  });

  function handleSend(e) {
    e.preventDefault();
    busy();
    api
      .sendMarketingSmsBroadcast({ id })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  }

  if (loading || isBusy) {
    return <CircularProgress />;
  }

  return (
    <Stack gap={3}>
      <DetailGrid
        title={
          <>
            <BackTo to={resourceViewRoute("marketing_sms_broadcast", state.broadcast)} />
            Review {state.broadcast.label}
          </>
        }
        properties={
          state.preReview
            ? [
                { label: "Sending From", value: state.broadcast.sendingNumberFormatted },
                { label: "Opt-out Field", value: state.broadcast.preferencesOptoutName },
                { label: "Lists", value: elementJoin(state.listLabels) },
                { label: "Total Recipients", value: state.totalRecipients },
                { label: "English Recipients", value: state.enRecipients },
                { label: "Spanish Recipients", value: state.esRecipients },
                { label: "Total Cost", value: `$${state.totalCost}` },
                { label: "English Cost", value: `$${state.enTotalCost}` },
                { label: "Spanish Cost", value: `$${state.esTotalCost}` },
              ]
            : [
                { label: "Sending From", value: state.broadcast.sendingNumberFormatted },
                { label: "Opt-out Field", value: state.broadcast.preferencesOptoutLabel },
                { label: "Lists", value: elementJoin(state.listLabels) },
                { label: "Total Recipients", value: state.totalRecipients },
                { label: "Delivered Recipients", value: state.deliveredRecipients },
                { label: "Failed Recipients", value: state.failedRecipients },
                { label: "Canceled Recipients", value: state.canceledRecipients },
                { label: "Pending Recipients", value: state.pendingRecipients },
                { label: "Actual Cost", value: `$${state.actualCost}` },
              ]
        }
      />
      {state.broadcast.sentAt ? (
        <Typography>
          This broadcast has already been sent. Pressing 'Re-send' will try to re-send any
          failed dispatches, but will not add any recipients.
        </Typography>
      ) : (
        <Typography>
          Once everything looks good, hit 'Send,' and the SMS messages will be sent in the
          background.
        </Typography>
      )}
      <Button variant="contained" onClick={handleSend}>
        {state.broadcast.sentAt ? "Re-send" : "Send"}
      </Button>
    </Stack>
  );
}
