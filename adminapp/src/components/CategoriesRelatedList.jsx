import AdminLink from "./AdminLink";
import RelatedListRemote from "./RelatedListRemote";
import React from "react";

export default function CategoriesRelatedList({ categories }) {
  return (
    <RelatedListRemote
      title="Categories"
      collection={categories}
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
