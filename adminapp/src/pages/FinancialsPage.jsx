import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress, Typography } from "@mui/material";
import React from "react";

export default function FinancialsPage() {
  const { state: platformStatus, loading } = useAsyncFetch(
    api.getFinancialsPlatformStatus,
    {
      default: {},
      pickData: true,
    }
  );
  if (loading) {
    return <CircularProgress />;
  }
  return (
    <>
      <Typography variant="h4" gutterBottom>
        Platform Financials
      </Typography>
      <DetailGrid
        title="Overview"
        anchorLeft
        properties={[
          { label: "Funding", children: <Money>{platformStatus.funding}</Money> },
          { label: "Payouts", children: <Money>{platformStatus.payouts}</Money> },
          { label: "Refunds", children: <Money>{platformStatus.refunds}</Money> },
          {
            label: "Member Liabilities",
            children: <Money>{platformStatus.memberLiabilities}</Money>,
          },
          { label: "Assets", children: <Money>{platformStatus.assets}</Money> },
        ]}
      />
      <RelatedList
        title="Unbalanced Ledgers"
        rows={platformStatus.unbalancedLedgers}
        headers={["Id", "Account", "Ledger", "Balance", "Debits", "Credits"]}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          <AdminLink key="account" model={row}>
            {row.accountName}
          </AdminLink>,
          row.name,
          <Money key="balance">{row.balance}</Money>,
          <Money key="debits">{row.totalDebits}</Money>,
          <Money key="credits">{row.totalCredits}</Money>,
        ]}
      />
      <RelatedList
        title="Platform Ledgers"
        rows={platformStatus.platformLedgers}
        headers={["Id", "Ledger", "Balance", "Debits", "Credits"]}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          row.name,
          <Money key="balance">{row.balance}</Money>,
          <Money key="debits">{row.totalDebits}</Money>,
          <Money key="credits">{row.totalCredits}</Money>,
        ]}
      />
    </>
  );
}
