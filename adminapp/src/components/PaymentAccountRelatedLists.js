import { dayjs } from "../modules/dayConfig";
import Money, { formatMoney } from "../shared/react/Money";
import AdminLink from "./AdminLink";
import Link from "./Link";
import RelatedList from "./RelatedList";
import map from "lodash/map";
import React from "react";

export default function PaymentAccountRelatedLists({ paymentAccount }) {
  if (!paymentAccount) {
    return null;
  }
  // TODO: receive this from backend somehow
  const sumaPlatformLedgerId = -1;
  return (
    <>
      <RelatedList
        title={`Ledgers - ${formatMoney(paymentAccount.totalBalance)}`}
        headers={["Id", "Currency", "Categories", "Balance", "New Transaction"]}
        rows={paymentAccount.ledgers}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          row.currency,
          map(row.vendorServiceCategories, "name").join(", "),
          <Money key="balance">{row.balance}</Money>,
          <Link
            key="transaction"
            to={`/book-transaction/new?originatingLedgerId=${sumaPlatformLedgerId}&receivingLedgerId=${row.id}`}
          >
            Create Book Transaction
          </Link>,
          row.softDeletedAt ? dayjs(row.softDeletedAt).format("lll") : "",
        ]}
      />
      {paymentAccount.ledgers.map((ledger) => (
        <RelatedList
          title={`Ledger ${ledger.label} (${ledger.id}) - ${formatMoney(ledger.balance)}`}
          key={ledger.id}
          headers={[
            "Id",
            "Created",
            "Applied",
            "Amount",
            "Category",
            "Originating",
            "Receiving",
          ]}
          rows={ledger.combinedBookTransactions}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            dayjs(row.createdAt).format("lll"),
            dayjs(row.applyAt).format("lll"),
            <Money key="amt">{row.amount}</Money>,
            row.associatedVendorServiceCategory.name,
            <AdminLink key="originating" model={row.originatingLedger}>
              {row.originatingLedger.adminLabel}
            </AdminLink>,
            <AdminLink key="receiving" model={row.receivingLedger}>
              {row.receivingLedger.adminLabel}
            </AdminLink>,
          ]}
        />
      ))}
      <RelatedList
        title="Originated Funding Transactions"
        rows={paymentAccount.originatedFundingTransactions}
        headers={["Id", "Created", "Status", "Amount"]}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          dayjs(row.createdAt).format("lll"),
          row.status,
          <Money key="amt">{row.amount}</Money>,
        ]}
      />
      <RelatedList
        title="Originated Payouts"
        rows={paymentAccount.originatedPayoutTransactions}
        headers={["Id", "Created", "Status", "Amount"]}
        keyRowAttr="id"
        toCells={(row) => [
          <AdminLink key="id" model={row} />,
          dayjs(row.createdAt).format("lll"),
          row.status,
          <Money key="amt">{row.amount}</Money>,
        ]}
      />
    </>
  );
}
