import { dayjs } from "../modules/dayConfig";
import { formatMoney, scaleMoney } from "../shared/money";
import Money from "../shared/react/Money";
import AdminLink from "./AdminLink";
import Link from "./Link";
import RelatedList from "./RelatedList";
import first from "lodash/first";
import get from "lodash/get";
import map from "lodash/map";
import React from "react";

export default function PaymentAccountRelatedLists({ paymentAccount }) {
  if (!paymentAccount) {
    return null;
  }
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
            to={`/book-transaction/new?originatingLedgerId=0&receivingLedgerId=${
              row.id
            }&vendorServiceCategorySlug=${get(
              first(row.vendorServiceCategories),
              "slug"
            )}`}
          >
            Add Book Credit
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
            <Money key="amt" accounting>
              {row.originatingLedger.id === ledger.id
                ? scaleMoney(row.amount, -1)
                : row.amount}
            </Money>,
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
