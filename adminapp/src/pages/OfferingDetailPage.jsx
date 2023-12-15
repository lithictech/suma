import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import oneLineAddress from "../modules/oneLineAddress";
import createRelativeUrl from "../shared/createRelativeUrl";
import Money from "../shared/react/Money";
import SumaImage from "../shared/react/SumaImage";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import CancelIcon from "@mui/icons-material/Cancel";
import CheckIcon from "@mui/icons-material/Check";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import ListAltIcon from "@mui/icons-material/ListAlt";
import SaveIcon from "@mui/icons-material/Save";
import { MenuItem, Select } from "@mui/material";
import IconButton from "@mui/material/IconButton";
import { makeStyles } from "@mui/styles";
import _ from "lodash";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function OfferingDetailPage() {
  const classes = useStyles();
  return (
    <ResourceDetail
      apiGet={api.getCommerceOffering}
      title={(model) => `Offering ${model.id}`}
      toEdit={(model) => `/offering/${model.id}/edit`}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Opening Date", value: dayjs(model.periodBegin) },
        { label: "Closing Date", value: dayjs(model.periodEnd) },
        {
          label: "Begin Fulfillment At",
          value: model.beginFulfillmentAt && dayjs(model.beginFulfillmentAt),
        },
        {
          label: "Prohibit Charge At Checkout",
          value: model.prohibitChargeAtCheckout ? "Yes" : "No",
        },
        {
          label: "Image",
          value: (
            <SumaImage
              image={model.image}
              alt={model.image.name}
              className="w-100"
              params={{ crop: "center" }}
              h={225}
              width={225}
            />
          ),
        },
        { label: "Description (En)", value: model.description.en },
        { label: "Description (Es)", value: model.description.es },
        { label: "Fulfillment Prompt (En)", value: model.fulfillmentPrompt.en },
        { label: "Fulfillment Prompt (Es)", value: model.fulfillmentPrompt.es },
        {
          label: "Fulfillment Confirmation (En)",
          value: model.fulfillmentConfirmation.en,
        },
        {
          label: "Fulfillment Confirmation (Es)",
          value: model.fulfillmentConfirmation.es,
        },
        {
          label: "Max ordered items, cumulative",
          value: model.maxOrderedItemsCumulative || "-",
        },
        {
          label: "Max ordered items, per-member",
          value: model.maxOrderedItemsPerMember || "-",
        },
        {
          label: "Pick/Pack list",
          value: !isEmpty(model.orders) ? (
            <Link to={`/offering/${model.id}/picklist`}>
              <ListAltIcon sx={{ verticalAlign: "middle", paddingRight: "5px" }} />
              Pick/Pack List
            </Link>
          ) : (
            "-"
          ),
        },
      ]}
    >
      {(model, setModel) => (
        <>
          <RelatedList
            title="Fulfillment Options"
            rows={model.fulfillmentOptions}
            headers={["Id", "Description", "Type", "Address"]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              row.description.en,
              row.type,
              row.address && oneLineAddress(row.address, false),
            ]}
          />
          <EligibilityConstraints
            offeringConstraints={model.eligibilityConstraints}
            offeringId={model.id}
            replaceOfferingData={setModel}
          />
          <RelatedList
            title={`Offering Products (${model.offeringProducts.length})`}
            rows={model.offeringProducts}
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
            to={createRelativeUrl(`/offering-product/new`, {
              offeringId: model.id,
              offeringLabel: model.description.en,
            })}
            sx={{ display: "block", marginTop: "15px" }}
          >
            <ListAltIcon sx={{ verticalAlign: "middle", paddingRight: "5px" }} />
            Create Offering Product
          </Link>
          <RelatedList
            title={`Orders (${model.orders.length})`}
            rows={model.orders}
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
        </>
      )}
    </ResourceDetail>
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
        value: "Offering has no constraints. All members can access it.",
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
