import api from "../api";
import config from "../config";
import { useGlobalApiState } from "../hooks/globalApiState";
import parseCurrency from "../modules/parseCurrency";
import { formatMoney } from "../shared/money";
import { InputAdornment, TextField } from "@mui/material";
import { makeStyles } from "@mui/styles";
import React from "react";

const CurrencyTextField = React.forwardRef(function CurrencyTextField(
  { money, onMoneyChange, ...rest },
  ref
) {
  const classes = useStyles();
  const currencies = useGlobalApiState(api.getCurrencies, [config.defaultCurrency], {
    pick: (r) => r.data.items,
  });
  const currency = currencies.find(({ code }) => money.currency === code);
  const [value, setValue] = React.useState(
    money.cents ? formatMoney(money, { noCurrency: true }) : ""
  );

  function handleChange(e) {
    setValue(e.target.value);
  }

  function reformat(e) {
    if (!e.target.value) {
      setValue("");
      onMoneyChange({ cents: 0, currency: currency.code });
      return;
    }
    const num = parseCurrency(e.target.value);
    const newMoney = { cents: num * 100, currency: currency.code };
    setValue(formatMoney(newMoney, { noCurrency: true }));
    onMoneyChange(newMoney);
  }

  return (
    <TextField
      {...rest}
      ref={ref}
      value={value}
      onChange={handleChange}
      onBlur={reformat}
      inputProps={{ className: classes.field }}
      InputProps={{
        startAdornment: (
          <InputAdornment position="start">{currency?.symbol}</InputAdornment>
        ),
      }}
    />
  );
});
export default CurrencyTextField;

const useStyles = makeStyles(() => ({ field: { textAlign: "right" } }));
