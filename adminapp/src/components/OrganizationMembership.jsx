import formatDate from "../modules/formatDate";
import AdminLink from "./AdminLink";
import CheckCircleOutlineIcon from "@mui/icons-material/CheckCircleOutline";
import VerifiedIcon from "@mui/icons-material/Verified";
import React from "react";

export function OrganizationMembershipUnverifiedIcon() {
  return (
    <CheckCircleOutlineIcon
      color="error"
      fontSize="small"
      sx={{ verticalAlign: "middle", marginRight: 1 }}
    />
  );
}

export function OrganizationMembershipVerifiedIcon() {
  return (
    <VerifiedIcon
      color="success"
      fontSize="small"
      sx={{ verticalAlign: "middle", marginRight: 1 }}
    />
  );
}

export function OrganizationMembershipRemovedIcon() {
  return (
    <VerifiedIcon
      color="disabled"
      fontSize="small"
      sx={{ verticalAlign: "middle", marginRight: 1 }}
    />
  );
}

export default function OrganizationMembership({ membership, detailed }) {
  if (membership.verifiedOrganization) {
    return (
      <>
        <AdminLink model={membership.verifiedOrganization}>
          <OrganizationMembershipVerifiedIcon />
          {membership.verifiedOrganization.name}
        </AdminLink>
        {detailed && <>&nbsp;(verified)</>}
      </>
    );
  }
  if (membership.unverifiedOrganizationName) {
    return (
      <span>
        <OrganizationMembershipUnverifiedIcon />
        {membership.unverifiedOrganizationName}
        {detailed && <>&nbsp;(unverified)</>}
      </span>
    );
  }
  return (
    <AdminLink model={membership.formerOrganization}>
      <OrganizationMembershipRemovedIcon />
      {membership.formerOrganization?.name}
      {detailed && (
        <>
          &nbsp;(removed{" "}
          {formatDate(membership.formerlyInOrganizationAt, {
            template: "l",
          })}
          )
        </>
      )}
    </AdminLink>
  );
}
