import api from "../api";
import Copyable from "../components/Copyable";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function ShortUrlDetailPage() {
  return (
    <ResourceDetail
      resource="short_url"
      apiGet={api.getShortUrl}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Short ID", value: model.shortId },
        {
          label: "Short URL",
          value: <Copyable inline text={model.shortUrl} />,
        },
        { label: "Long URL", value: model.longUrl },
        { label: "Timestamp", value: dayjs(model.insertedAt) },
      ]}
    />
  );
}
