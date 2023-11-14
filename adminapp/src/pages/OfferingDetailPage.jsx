import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import oneLineAddress from "../modules/oneLineAddress";
import Money from "../shared/react/Money";
import SumaImage from "../shared/react/SumaImage";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import CancelIcon from "@mui/icons-material/Cancel";
import CheckIcon from "@mui/icons-material/Check";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import ListAltIcon from "@mui/icons-material/ListAlt";
import SaveIcon from "@mui/icons-material/Save";
import { CircularProgress, MenuItem, Select } from "@mui/material";
import IconButton from "@mui/material/IconButton";
import { makeStyles } from "@mui/styles";
import _ from "lodash";
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
          <EligibilityConstraints
            offeringConstraints={offering.eligibilityConstraints}
            offeringId={id}
            replaceOfferingData={updateOffering}
          />
          <RelatedList
            title={`Offering Products (${offering.offeringProducts.length})`}
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
          <Link
            to={`/offering-product/new?offeringId=${offering.id}&offeringDescription=${offering.description}`}
            sx={{ display: "block", marginTop: "15px" }}
          >
            <ListAltIcon sx={{ verticalAlign: "middle", paddingRight: "5px" }} />
            Create Offering Product
          </Link>
          {!isEmpty(offering.orders) && (
            <Link to={`/offering/${offering.id}/picklist`}>
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

function EligibilityConstraints({
  offeringConstraints,
  offeringId,
  replaceOfferingData,
}) {
  const [editing, setEditing] = React.useState(false);
  const [updatedConstraints, setUpdatedConstraints] = React.useState([]);
  const [newConstraintId, setNewConstraintId] = React.useState(0);
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const { state: eligibilityConstraints, loading: eligibilityConstraintsLoading } =
    useAsyncFetch(api.getEligibilityConstraintsMeta, {
      pickData: true,
    });

  function startEditing() {
    setEditing(true);
    setUpdatedConstraints(offeringConstraints);
    setNewConstraintId(eligibilityConstraints[0]?.id);
  }

  if (!editing) {
    const properties = [];
    if (_.isEmpty(offeringConstraints)) {
      properties.push({
        label: "*",
        value:
          "Member has no constraints. They can access any goods and services that are unconstrained.",
      });
    } else {
      offeringConstraints.forEach(({ name }) =>
        properties.push({
          label: name,
          value: <CheckIcon />,
        })
      );
    }
    return (
      <div>
        <DetailGrid
          title={
            <>
              Eligibility Constraints
              <IconButton onClick={startEditing}>
                <EditIcon color="info" />
              </IconButton>
            </>
          }
          properties={properties}
        />
      </div>
    );
  }

  if (eligibilityConstraintsLoading) {
    return "Loading...";
  }

  function discardChanges() {
    setUpdatedConstraints([]);
    setEditing(false);
  }

  function saveChanges() {
    const constraintIds = updatedConstraints.map((c) => c.id);
    if (newConstraintId) {
      constraintIds.push(newConstraintId);
    }
    api
      .updateOfferingEligibilityConstraints({
        id: offeringId,
        constraintIds,
      })
      .then((r) => {
        replaceOfferingData(r.data);
        setEditing(false);
      })
      .catch(enqueueErrorSnackbar);
  }

  function deleteConstraint(id) {
    setUpdatedConstraints(updatedConstraints.filter((c) => c.id !== id));
  }

  const properties = updatedConstraints.map((c) => ({
    label: c.name,
    children: (
      <IconButton onClick={() => deleteConstraint(c.id)}>
        <DeleteIcon color="error" />
      </IconButton>
    ),
  }));

  const existingConstraintIds = offeringConstraints.map((c) => c.id);
  const availableConstraints = eligibilityConstraints.items.filter(
    (c) => !existingConstraintIds.includes(c.id)
  );
  if (!_.isEmpty(availableConstraints)) {
    properties.push({
      label: "Add Constraint",
      children: (
        <div>
          <Select
            value={newConstraintId || ""}
            onChange={(e) => setNewConstraintId(Number(e.target.value))}
          >
            {availableConstraints.map((c) => (
              <MenuItem key={c.id} value={c.id}>
                {c.name}
              </MenuItem>
            ))}
          </Select>
        </div>
      ),
    });
  }
  return (
    <div>
      <DetailGrid
        title={
          <>
            Eligibility Constraints
            <IconButton onClick={saveChanges}>
              <SaveIcon color="success" />
            </IconButton>
            <IconButton onClick={discardChanges}>
              <CancelIcon color="error" />
            </IconButton>
          </>
        }
        properties={properties}
      />
    </div>
  );
}

const useStyles = makeStyles(() => ({
  closed: {
    opacity: 0.5,
  },
}));
