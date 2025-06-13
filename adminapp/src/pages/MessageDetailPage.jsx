import api from "../api";
import AdminActions from "../components/AdminActions";
import AdminLink from "../components/AdminLink";
import ExternalLinks from "../components/ExternalLinks";
import ResourceDetail from "../components/ResourceDetail";
import formatDate from "../modules/formatDate";
import { Typography } from "@mui/material";
import Box from "@mui/material/Box";
import React from "react";

export default function MessageDetailPage() {
  return (
    <ResourceDetail
      resource="message_delivery"
      apiGet={api.getMessageDelivery}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Template", value: model.template },
        {
          label: "Transport",
          value: `${model.transportService} (${model.transportType})`,
        },
        { label: "MessageId", value: model.transportMessageId },
        { label: "Template", value: model.template },
        { label: "CreatedAt", value: formatDate(model.createdAt) },
        { label: "SentAt", value: formatDate(model.sentAt) },
        { label: "AbortedAt", value: formatDate(model.abortedAt) },
        model.recipient && {
          label: "Recipient",
          value: (
            <AdminLink key="recipient" model={model.recipient}>
              {model.recipient.name} ({model.to})
            </AdminLink>
          ),
        },
      ]}
    >
      {(model) =>
        model.bodies.map(({ id, mediatype, content }) => [
          <ExternalLinks externalLinks={model.externalLinks} />,
          <AdminActions adminActions={model.adminActions} />,
          <Box key={id} mt={3}>
            <hr />
            <Typography variant="h6">
              Body {id} ({mediatype})
            </Typography>
            <div>
              <div dangerouslySetInnerHTML={{ __html: content }} />
            </div>
          </Box>,
        ])
      }
    </ResourceDetail>
  );
}
