import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import InlineEditField from "../components/InlineEditField";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import oneLineAddress from "../modules/oneLineAddress";
import Money from "../shared/react/Money";
import SumaImage from "../shared/react/SumaImage";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import ListAltIcon from "@mui/icons-material/ListAlt";
import {
  Chip,
  CircularProgress,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
} from "@mui/material";
import { makeStyles } from "@mui/styles";
import capitalize from "lodash/capitalize";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function OfferingDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  const classes = useStyles();
  id = Number(id);
  const getCommerceOffering = React.useCallback(() => {
    return api.getCommerceOffering({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const {
    state: offering,
    loading: offeringLoading,
    replaceState: updateOffering,
  } = useAsyncFetch(getCommerceOffering, {
    default: {},
    pickData: true,
  });
  const { state: allEligibilityConstraints } = useAsyncFetch(
    api.getEligibilityConstraints,
    {
      pickData: true,
    }
  );

  const handleAddEligibilityConstraint = (c) => {
    return api
      .addOfferingEligibility(c)
      .then(api.pickData)
      .then((o) => {
        updateOffering(o);
      })
      .catch((e) => enqueueErrorSnackbar(e));
  };

  return (
    <>
      {offeringLoading && <CircularProgress />}
      {!isEmpty(offering) && (
        <div>
          <DetailGrid
            title={`Offering ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(offering.createdAt) },
              { label: "Opening Date", value: dayjs(offering.opensAt) },
              { label: "Closing Date", value: dayjs(offering.closesAt) },
              {
                label: "Begin Fulfillment At",
                value: offering.beginFulfillmentAt && dayjs(offering.beginFulfillmentAt),
              },
              {
                label: "Prohibit Charge At Checkout",
                value: offering.prohibitChargeAtCheckout ? "Yes" : "No",
              },
              {
                label: "Image",
                value: (
                  <SumaImage
                    image={offering.image}
                    alt={offering.image.name}
                    className="w-100"
                    params={{ crop: "center" }}
                    h={225}
                    width={225}
                  />
                ),
              },
              {
                label: "Eligibility Constraints",
                children: (
                  <InlineEditField
                    renderDisplay={
                      !isEmpty(offering.eligibilityConstraints)
                        ? offering.eligibilityConstraints.map(({ name }) => (
                            <Chip
                              key={name}
                              label={capitalize(name)}
                              sx={{ margin: 0.5 }}
                            />
                          ))
                        : "-"
                    }
                    initialEditingState={{ id: offering.id }}
                    renderEdit={(st, set) => {
                      return (
                        <FormControl required size="small">
                          <InputLabel>Choose new constraint...</InputLabel>
                          <Select
                            label="Choose new constraint..."
                            value={st.constraintId || ""}
                            sx={{ width: "250px" }}
                            onChange={(e) => set({ ...st, constraintId: e.target.value })}
                          >
                            {allEligibilityConstraints.items.map((c) => (
                              <MenuItem key={c.id} value={c.id}>
                                {c.name}
                              </MenuItem>
                            ))}
                          </Select>
                        </FormControl>
                      );
                    }}
                    onSave={handleAddEligibilityConstraint}
                  />
                ),
              },
              { label: "Description", value: offering.description },
              { label: "Fulfillment Prompt", value: offering.fulfillmentPrompt },
              {
                label: "Fulfillment Confirmation",
                value: offering.fulfillmentConfirmation,
              },
            ]}
          />
          <RelatedList
            title="Fulfillment Options"
            rows={offering.fulfillmentOptions}
            headers={["Id", "Description", "Type", "Address"]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              row.description,
              row.type,
              row.address && oneLineAddress(row.address, false),
            ]}
          />
          <RelatedList
            title={`Products (${offering.offeringProducts.length})`}
            rows={offering.offeringProducts}
            headers={["Id", "Name", "Vendor", "Customer Price", "Full Price"]}
            keyRowAttr="id"
            rowClass={(row) => (row.closedAt ? classes.closed : "")}
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              <AdminLink key="id" model={row}>
                {row.productName}
              </AdminLink>,
              row.vendorName,
              <Money key="customer_price">{row.customerPrice}</Money>,
              <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
            ]}
          />
          {!isEmpty(offering.orders) && (
            <Link
              to={`/offering/${offering.id}/picklist`}
              sx={{ display: "inline-block", marginTop: "15px" }}
            >
              <ListAltIcon sx={{ verticalAlign: "middle", paddingRight: "5px" }} />
              Pick/Pack List
            </Link>
          )}
          <RelatedList
            title={`Orders (${offering.orders.length})`}
            rows={offering.orders}
            headers={["Id", "Created", "Member", "Items", "Status"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key="mem" model={row.member}>
                {row.member.name}
              </AdminLink>,
              row.totalItemCount,
              row.statusLabel,
            ]}
          />
        </div>
      )}
    </>
  );
}

const useStyles = makeStyles(() => ({
  closed: {
    opacity: 0.5,
  },
}));
