import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import dateFormat from "../shared/dateFormat";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress, Typography } from "@mui/material";
import Box from "@mui/material/Box";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function MessageDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getMessageDelivery = React.useCallback(() => {
    return api.getMessageDelivery({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: message, loading: messageLoading } = useAsyncFetch(getMessageDelivery, {
    default: {},
    pickData: true,
  });
  const recipient = message.recipient || {};
  return (
    <>
      {messageLoading && <CircularProgress />}
      {!isEmpty(message) && (
        <div>
          <DetailGrid
            title={`Message ${message.id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Template", value: message.template },
              {
                label: "Transport",
                value: `${message.transportService} (${message.transportType})`,
              },
              { label: "MessageId", value: message.transportMessageId },
              { label: "Template", value: message.template },
              { label: "CreatedAt", value: dateFormat(message.createdAt, "lll") },
              { label: "SentAt", value: dateFormat(message.sentAt, "lll") },
              { label: "AbortedAt", value: dateFormat(message.abortedAt, "lll") },
              {
                label: "Recipient",
                value: (
                  <AdminLink key="recipient" model={recipient}>
                    {recipient.name} ({message.to})
                  </AdminLink>
                ),
              },
            ]}
          />
          {message.bodies.map(({ id, mediatype, content }) => {
            return (
              <Box key={id} mt={3}>
                <hr />
                <Typography variant="h6">
                  Body {id} ({mediatype})
                </Typography>
                <div>
                  <div dangerouslySetInnerHTML={{ __html: content }} />
                </div>
              </Box>
            );
          })}
        </div>
      )}
    </>
  );
}
