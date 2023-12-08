import api from "../api";
import AdminLink from "../components/AdminLink";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { Typography } from "@mui/material";
import { alpha, styled } from "@mui/material/styles";
import { DataGrid, gridClasses } from "@mui/x-data-grid";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Link, useParams } from "react-router-dom";

export default function OfferingPickListPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getCommerceOfferingPickList = React.useCallback(() => {
    return api.getCommerceOfferingPickList({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: pickList } = useAsyncFetch(getCommerceOfferingPickList, {
    default: {},
    pickData: true,
  });
  return (
    <>
      {!isEmpty(pickList) && (
        <>
          <Typography variant="h5" gutterBottom>
            Offering <Link to={`/offering/${id}`}>{id}</Link> Pick/Pack List
          </Typography>
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
                sortComparator,
              },
              {
                field: "ordersItemsQuantities",
                headerName: "Total",
              },
            ]}
            rows={pickList.offeringProductsQuantities || []}
            getRowId={(row) => row.id}
            {...commonTableProps}
          />
          <StripedDataGrid
            columns={[
              {
                field: "offeringProduct",
                headerName: "Product",
                width: 250,
                valueGetter: (params) => params.row.offeringProduct.product,
                renderCell: ({ value }) => (
                  <AdminLink model={value} title={value}>
                    {value.name}
                  </AdminLink>
                ),
              },
              {
                field: "fulfillmentOption",
                headerName: "Fulfillment",
                width: 300,
                valueGetter: (params) => params.row.fulfillmentOption.description,
              },
              {
                field: "quantities",
                headerName: "Total",
              },
            ]}
            rows={pickList.offeringProductsFulfillmentsQuantities || []}
            getRowId={(row) =>
              row?.offeringProduct.id + row?.fulfillmentOption.description
            }
            {...commonTableProps}
          />
          <StripedDataGrid
            columns={[
              {
                field: "serial",
                headerName: "Serial",
              },
              {
                field: "member",
                headerName: "Member",
                width: 150,
                renderCell: ({ value }) => (
                  <AdminLink model={value} title={value}>
                    {value.name}
                  </AdminLink>
                ),
                sortComparator,
              },
              {
                field: "quantity",
                headerName: "Quantity",
              },
              {
                field: "product",
                headerName: "Product",
                width: 200,
                renderCell: ({ value }) => (
                  <AdminLink model={value} title={value}>
                    {value.name}
                  </AdminLink>
                ),
                sortComparator,
              },
              {
                field: "fulfillment",
                headerName: "Fulfillment",
                width: 300,
              },
            ]}
            rows={pickList.items || []}
            getRowId={(row) => row.id}
            checkboxSelection={true}
            {...commonTableProps}
          />
        </>
      )}
    </>
  );
}
const sortComparator = (v1, v2) => v1.name.localeCompare(v2.name);
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
