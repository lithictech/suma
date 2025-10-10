import api from "../api";
import { useGlobalApiState } from "../hooks/globalApiState";
import { FormControl, FormHelperText, InputLabel, MenuItem, Select } from "@mui/material";
import React from "react";

const StateMachineStateSelect = React.forwardRef(function StateMachineStateSelect(
  { label, stateMachineName, value, defaultValue, className, sx, onChange, ...rest },
  ref
) {
  label = label || "Status";
  const stateMachineData = useGlobalApiState(
    (data, ...args) => api.getStateMachine({ ...data, name: stateMachineName }, ...args),
    { stateNames: [] },
    { key: `state-machine-${stateMachineName}` }
  );

  return (
    <FormControl className={className} sx={sx}>
      {label && <InputLabel htmlFor="smstate-select">{label}</InputLabel>}
      <Select
        id="smstate-select"
        ref={ref}
        value={value}
        label={label}
        onChange={onChange}
        {...rest}
      >
        {stateMachineData.stateNames.map((name) => (
          <MenuItem key={name} value={name}>
            {name}
          </MenuItem>
        ))}
      </Select>
      <FormHelperText>
        Manually changing states bypasses important code and should only be done if
        you&rsquo;re confident it&rsquo;s safe.
      </FormHelperText>
    </FormControl>
  );
});
export default StateMachineStateSelect;
