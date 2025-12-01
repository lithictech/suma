import AdminLink from "./AdminLink";
import RelatedList from "./RelatedList";
import React from "react";

export default function CategoriesRelatedList({ categories }) {
  return (
    <RelatedList
      title="Categories"
      rows={categories}
      headers={["Id", "Name", "Slug", "Parent"]}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink model={row} />,
        row.name,
        row.slug,
        row.parent ? <AdminLink model={row.parent}>{row.parent.name}</AdminLink> : null,
      ]}
    />
  );
}
