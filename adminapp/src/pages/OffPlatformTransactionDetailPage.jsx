import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import relativeLink from "../modules/relativeLink";
import useMountEffect from "../shared/react/useMountEffect";
import { CircularProgress } from "@mui/material";
import React from "react";
import { useNavigate, useParams } from "react-router-dom";

export default function OffPlatformTransactionDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  useMountEffect(() => {
    api
      .getOffPlatformTransaction({ id })
      .then((r) =>
        navigate(relativeLink(r.data.transactionAdminLink)[0], { replace: true })
      )
      .catch(enqueueErrorSnackbar);
  });
  return <CircularProgress />;
}
