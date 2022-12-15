import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { Link, Typography } from "@mui/material";
import { alpha, styled } from "@mui/material/styles";
import { DataGrid, gridClasses } from "@mui/x-data-grid";
import React from "react";
import { useParams } from "react-router-dom";

export default function OfferingPickListPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getCommerceOfferingPickList = React.useCallback(() => {
    return api
      .getCommerceOfferingPickList({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: pickList } = useAsyncFetch(getCommerceOfferingPickList, {
    default: {},
    pickData: true,
  });
  return (
    <>
      <Typography variant="h5" gutterBottom>
        Offering <Link href={`/offering/${id}`}>{id}</Link> Pick/Pack List
      </Typography>
      <StripedDataGrid
        columns={[
          {
            field: "id",
            headerName: "ID",
          },
          {
            field: "member",
            headerName: "Member",
            renderCell: ({ value }) => <Link href={value.adminLink}>{value.name}</Link>,
          },
          {
            field: "quantity",
            headerName: "Quantity",
          },
          {
            field: "product",
            headerName: "Product",
            width: 125,
            renderCell: ({ value }) => <Link href={value.adminLink}>{value.name}</Link>,
          },
          {
            field: "fulfillment",
            headerName: "Fulfillment",
            width: 125,
          },
        ]}
        rows={pickList.items || []}
        autoHeight={true}
        hideFooter={true}
        checkboxSelection={true}
        getRowClassName={(params) =>
          params.indexRelativeToCurrentPage % 2 === 0 ? "even" : "odd"
        }
      />
    </>
  );
}

const ODD_OPACITY = 0.2;
const StripedDataGrid = styled(DataGrid)(({ theme }) => ({
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
