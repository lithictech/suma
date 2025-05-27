import api from "../api";
import DetailGrid from "../components/DetailGrid";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import elementJoin from "../modules/elementJoin";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { Button, CircularProgress, Stack, Typography } from "@mui/material";
import React from "react";
import { useNavigate, useParams } from "react-router-dom";

export default function MarketingSmsCampaignSendPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { isBusy, busy, notBusy } = useBusy();
  const navigate = useNavigate();
  const { id } = useParams();
  const getMarketingSmsCampaignReview = React.useCallback(() => {
    return api.getMarketingSmsCampaignReview({ id }).catch(enqueueErrorSnackbar);
  }, [enqueueErrorSnackbar, id]);
  const { state, loading } = useAsyncFetch(getMarketingSmsCampaignReview, {
    default: {},
    pickData: true,
  });

  function handleSend(e) {
    e.preventDefault();
    busy();
    api
      .sendMarketingSmsCampaign({ id })
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
        title={`Review ${state.campaign.label}`}
        properties={[
          { label: "Lists", value: elementJoin(state.listLabels) },
          { label: "Total Recipients", value: state.totalRecipientCount },
          { label: "English Recipients", value: state.enRecipientCount },
          { label: "Spanish Recipients", value: state.esRecipientCount },
          { label: "Total Cost", value: `$${state.totalCost}` },
          { label: "English Cost", value: `$${state.enTotalCost}` },
          { label: "Spanish Cost", value: `$${state.esTotalCost}` },
        ]}
      />
      {state.campaign.sentAt ? (
        <Typography>
          This campaign has already been sent. Pressing 'Re-send' will try to re-send any
          failed dispatches, but will not add any recipients.
        </Typography>
      ) : (
        <Typography>
          Once everything looks good, hit 'Send,' and the SMS messages will be sent in the
          background.
        </Typography>
      )}
      <Button variant="contained" onClick={handleSend}>
        {state.campaign.sentAt ? "Re-send" : "Send"}
      </Button>
    </Stack>
  );
}
