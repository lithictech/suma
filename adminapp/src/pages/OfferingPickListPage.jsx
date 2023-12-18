import api from "../api";
import AdminLink from "../components/AdminLink";
import Link from "../components/Link";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useClientsideSearchParams from "../shared/react/useClientsideSearchParams";
import "./OfferingPickListPage.css";
import {
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  Typography,
} from "@mui/material";
import { alpha, styled } from "@mui/material/styles";
import { DataGrid, gridClasses } from "@mui/x-data-grid";
import get from "lodash/get";
import isEmpty from "lodash/isEmpty";
import keyBy from "lodash/keyBy";
import map from "lodash/map";
import sortBy from "lodash/sortBy";
import uniqBy from "lodash/uniqBy";
import React from "react";
import { formatPhoneNumber } from "react-phone-number-input";
import { useParams } from "react-router-dom";

export default function OfferingPickListPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getCommerceOfferingPickList = React.useCallback(() => {
    return api.getCommerceOfferingPickList({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: picklist } = useAsyncFetch(getCommerceOfferingPickList, {
    default: { orderItems: [] },
    pickData: true,
  });
  const { searchParams, setSearchParam } = useClientsideSearchParams();
  const selectedProduct = searchParams.get("product") || "";
  const selectedFulfillment = searchParams.get("fulfillment") || "";
  const productChoices = picklist.orderItems.map((oi) => ({
    label: oi.offeringProduct.product.name,
    value: oi.offeringProduct.product.id,
  }));
  const fulfillmentChoices = picklist.orderItems.map((oi) => ({
    label: oi.fulfillmentOption.description,
    value: oi.fulfillmentOption.id,
  }));
  function selectFilterMenuItems(allChoices) {
    const ch = sortBy(uniqBy(allChoices, "value"), "label");
    const withEmpty = [{ label: "All", value: null }, ...ch];
    return withEmpty.map(({ label, value }) => (
      <MenuItem key={value} value={value}>
        {label}
      </MenuItem>
    ));
  }
  const productMatches = React.useCallback(
    (pr) => !selectedProduct || pr.id === Number(selectedProduct),
    [selectedProduct]
  );
  const fulfillmentOptMatches = React.useCallback(
    (fo) => !selectedFulfillment || fo.id === Number(selectedFulfillment),
    [selectedFulfillment]
  );
  const matchingItems = (picklist.orderItems || []).filter(
    (oi) =>
      productMatches(oi.offeringProduct.product) &&
      fulfillmentOptMatches(oi.fulfillmentOption)
  );
  const productsById = keyBy(map(matchingItems, "offeringProduct.product"), "id");
  const fulfillmentsById = keyBy(map(matchingItems, "fulfillmentOption"), "id");
  const productIdsAndQuantities = {};
  const fulfillmentIdsAndProductQuantities = {};
  matchingItems.forEach(({ offeringProduct, fulfillmentOption, quantity }) => {
    const pid = offeringProduct.product.id;
    productIdsAndQuantities[pid] ||= 0;
    productIdsAndQuantities[pid] += quantity;
    fulfillmentIdsAndProductQuantities[fulfillmentOption.id] ||= {};
    fulfillmentIdsAndProductQuantities[fulfillmentOption.id][pid] ||= 0;
    fulfillmentIdsAndProductQuantities[fulfillmentOption.id][pid] += quantity;
  });
  const fulfillmentAndProductQuantityRows = [];
  Object.entries(fulfillmentIdsAndProductQuantities).forEach(([fid, pq]) => {
    Object.entries(pq).forEach(([pid, q]) => {
      fulfillmentAndProductQuantityRows.push({
        product: productsById[pid],
        fulfillmentOption: fulfillmentsById[fid],
        quantity: q,
      });
    });
  });
  return (
    <>
      {!isEmpty(picklist) && (
        <>
          <Typography variant="h5" gutterBottom>
            <Link to={`/offering/${id}`}>Offering {id}</Link> Pick/Pack List
          </Typography>
          <Stack direction="row" gap={1} sx={{ marginY: 1 }}>
            <FormControl sx={{ flex: 1, maxWidth: 300 }}>
              <InputLabel>Product</InputLabel>
              <Select
                value={selectedProduct}
                label="Product"
                onChange={(e) => setSearchParam("product", e.target.value || null)}
              >
                {selectFilterMenuItems(productChoices)}
              </Select>
            </FormControl>
            <FormControl sx={{ flex: 1, maxWidth: 300 }}>
              <InputLabel>Fulfillment</InputLabel>
              <Select
                value={selectedFulfillment}
                label="Fulfillment"
                onChange={(e) => setSearchParam("fulfillment", e.target.value || null)}
              >
                {selectFilterMenuItems(fulfillmentChoices)}
              </Select>
            </FormControl>
          </Stack>
          <StripedDataGrid
            columns={[
              {
                field: "product",
                headerName: "Product",
                width: 250,
                renderCell: ({ value }) => (
                  <AdminLink key="id" model={value}>
                    {value.name}
                  </AdminLink>
                ),
                sortComparator: nameComparator,
              },
              {
                field: "quantity",
                headerName: "Qty",
                width: 50,
              },
            ]}
            rows={Object.entries(productIdsAndQuantities).map(([pid, quantity]) => ({
              product: productsById[pid],
              quantity,
            }))}
            getRowId={(row) => row.product.id}
            {...commonTableProps}
          />
          <StripedDataGrid
            columns={[
              {
                field: "product",
                headerName: "Product",
                width: 250,
                renderCell: ({ value }) => (
                  <AdminLink model={value} title={value}>
                    {value.name}
                  </AdminLink>
                ),
                sortComparator: nameComparator,
              },
              {
                field: "fulfillmentOption",
                headerName: "Fulfillment",
                width: 350,
                renderCell: ({ value }) => value.description,
              },
              {
                field: "quantity",
                headerName: "Qty",
                width: 50,
              },
            ]}
            rows={fulfillmentAndProductQuantityRows}
            getRowId={(row) => `${row.product.id}-${row.fulfillmentOption.id}`}
            {...commonTableProps}
          />
          <StripedDataGrid
            columns={[
              {
                field: "serial",
                headerName: "Serial",
                width: 60,
              },
              {
                field: "member",
                headerName: "Member",
                width: 125,
                renderCell: ({ value }) => (
                  <AdminLink model={value} title={value}>
                    {value.name}
                  </AdminLink>
                ),
                sortComparator: nameComparator,
              },
              {
                field: "member.phone",
                headerName: "Phone",
                width: 125,
                valueGetter: ({ row }) => row.member.phone,
                renderCell: ({ value }) => {
                  return formatPhoneNumber("+" + value);
                },
              },
              {
                field: "quantity",
                headerName: "Qty",
                width: 50,
              },
              {
                field: "offeringProduct",
                headerName: "Product",
                width: 200,
                renderCell: ({ value }) => (
                  <AdminLink model={value} title={value}>
                    {value.product.name}
                  </AdminLink>
                ),
                sortComparator: newLocaleComparator("product.name"),
              },
              {
                field: "fulfillmentOption",
                headerName: "Fulfillment",
                width: 250,
                renderCell: ({ value }) => value.description,
              },
              {
                field: "status",
                headerName: "Status",
                width: 100,
              },
            ]}
            rows={matchingItems}
            getRowId={(row) => row.id}
            {...commonTableProps}
          />
        </>
      )}
    </>
  );
}

function newLocaleComparator(f) {
  return (a, b) => get(a, f).localeCompare(get(b, f));
}
const nameComparator = newLocaleComparator("name");

const commonTableProps = {
  getRowClassName: ({ indexRelativeToCurrentPage }) =>
    indexRelativeToCurrentPage % 2 === 0 ? "even" : "odd",
  sx: {
    "& .MuiDataGrid-cell > *": {
      overflow: "hidden!important",
      textOverflow: "ellipsis!important",
    },
  },
  density: "compact",
  autoHeight: true,
  hideFooter: true,
};

const ODD_OPACITY = 0.2;
const StripedDataGrid = styled(DataGrid)(({ theme }) => ({
  marginBottom: theme.spacing(3),
  [`& .${gridClasses.row}.even`]: {
    backgroundColor: theme.palette.grey[200],
    "&:hover, &.Mui-hovered": {
      backgroundColor: alpha(theme.palette.secondary.main, ODD_OPACITY),
      "@media (hover: none)": {
        backgroundColor: "transparent",
      },
    },
    "&.Mui-selected": {
      backgroundColor: alpha(
        theme.palette.secondary.main,
        ODD_OPACITY + theme.palette.action.selectedOpacity
      ),
      "&:hover, &.Mui-hovered": {
        backgroundColor: alpha(
          theme.palette.secondary.main,
          ODD_OPACITY +
            theme.palette.action.selectedOpacity +
            theme.palette.action.hoverOpacity
        ),
        // Reset on touch devices, it doesn't add specificity
        "@media (hover: none)": {
          backgroundColor: alpha(
            theme.palette.secondary.main,
            ODD_OPACITY + theme.palette.action.selectedOpacity
          ),
        },
      },
    },
  },
}));
