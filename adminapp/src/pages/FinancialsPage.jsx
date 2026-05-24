import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import HelmetTitle from "../components/HelmetTitle";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import RelatedListRemote from "../components/RelatedListRemote";
import formatDate from "../modules/formatDate";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress, Stack, Typography } from "@mui/material";
import Button from "@mui/material/Button";
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
    <Stack gap={2}>
      <HelmetTitle title="Platform Financials" />
      <Typography variant="h4" gutterBottom>
        Platform Financials
      </Typography>
      <DetailGrid
        title="Overview"
        anchorLeft
        properties={[
          {
            label: "Funding",
            children: (
              <SumCount
                amount={platformStatus.funding}
                count={platformStatus.fundingCount}
              />
            ),
          },
          {
            label: "Payouts",
            children: (
              <SumCount
                amount={platformStatus.payouts}
                count={platformStatus.payoutCount}
              />
            ),
          },
          {
            label: "Refunds",
            children: (
              <SumCount
                amount={platformStatus.refunds}
                count={platformStatus.refundCount}
              />
            ),
          },
          {
            label: "Member Liabilities",
            children: <Money>{platformStatus.memberLiabilities}</Money>,
          },
          { label: "Assets", children: <Money>{platformStatus.assets}</Money> },
        ]}
      />
      <Button component={Link} href={"/payment-off-platform/create"}>
        Create Off-Platform Funding/Payout
      </Button>
      <RelatedListRemote
        title="Unbalanced Ledgers"
        collection={platformStatus.unbalancedLedgers}
        headers={["Id", "Account", "Ledger", "Balance", "Debits", "Credits"]}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          <AdminLink key="account" model={row}>
            {row.accountName}
          </AdminLink>,
          row.name,
          ...ledgerMonies(row),
        ]}
      />
      <RelatedListRemote
        title="Platform Ledgers"
        collection={platformStatus.platformLedgers}
        headers={["Id", "Ledger", "Balance", "Debits", "Credits"]}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          row.name,
          ...ledgerMonies(row),
        ]}
      />
      <RelatedListRemote
        title="Off Platform Funding"
        collection={platformStatus.offPlatformFundingTransactions}
        headers={["Id", "At", "Amount", "Note"]}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          formatDate(row.transactedAt),
          <Money>{row.amount}</Money>,
          row.note,
        ]}
      />
      <RelatedListRemote
        title="Off Platform Payouts"
        collection={platformStatus.offPlatformPayoutTransactions}
        headers={["Id", "At", "Amount", "Note"]}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          formatDate(row.transactedAt),
          <Money>{row.amount}</Money>,
          row.note,
        ]}
      />
    </Stack>
  );
}

function ledgerMonies(row) {
  return [
    <Money key="balance">{row.balance}</Money>,
    <SumCount key="debits" amount={row.totalDebits} count={row.countDebits} />,
    <SumCount key="credits" amount={row.totalCredits} count={row.countCredits} />,
  ];
}

function SumCount({ amount, count }) {
  return (
    <>
      <Money>{amount}</Money> ({count})
    </>
  );
}
