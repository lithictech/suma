import api from "../api";
import AdminLink from "../components/AdminLink";
import Copyable from "../components/Copyable";
import FabAdd from "../components/FabAdd";
import ResourceList from "../components/ResourceList";
import formatDate from "../modules/formatDate";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";
import { useNavigate } from "react-router-dom";

export default function ShortUrlListPage() {
  const navigate = useNavigate();

  function handleCreate() {
    api.createShortUrl().then((r) => navigate(`/short-url/${r.data.id}/edit`));
  }

  return (
    <>
      <FabAdd onClick={handleCreate} />
      <ResourceList
        resource="short_url"
        apiList={api.getShortUrls}
        canSearch
        columns={[
          {
            id: "id",
            label: "ID",
            align: "right",
            sortable: true,
            render: (c) => <AdminLink model={c} />,
          },
          {
            id: "shortId",
            label: "Short ID",
            align: "left",
            sortable: true,
            render: (c) => (
              <>
                <Copyable
                  buttonOnly
                  inline
                  iconProps={{ fontSize: "small", color: "primary" }}
                  text={c.shortUrl}
                />
                <AdminLink model={c}>{c.shortId}</AdminLink>
              </>
            ),
          },
          {
            id: "longUrl",
            label: "URL",
            align: "left",
            sortable: true,
            render: (c) => (
              <SafeExternalLink href={c.longUrl}>{c.longUrl}</SafeExternalLink>
            ),
          },
          {
            id: "insertedAt",
            label: "Timestamp",
            align: "left",
            sortable: true,
            render: (c) => formatDate(c.insertedAt),
          },
        ]}
      />
    </>
  );
}
