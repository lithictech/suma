import { dayjs } from "../modules/dayConfig";
import { formatMoney } from "../shared/money";
import Money from "../shared/react/Money";
import AdminLink from "./AdminLink";
import LedgerBookTransactionsRelatedList from "./LedgerBookTransactionRelatedList";
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
        <LedgerBookTransactionsRelatedList
          ledger={ledger}
          title={`Ledger ${ledger.label} (${ledger.id}) - ${formatMoney(ledger.balance)}`}
          key={ledger.id}
          rows={ledger.combinedBookTransactions}
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
