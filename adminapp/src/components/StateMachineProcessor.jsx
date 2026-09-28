import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useToggle from "../shared/react/useToggle";
import Link from "./Link";
import ArrowRightIcon from "@mui/icons-material/ArrowRight";
import Button from "@mui/material/Button";
import ButtonGroup from "@mui/material/ButtonGroup";
import ClickAwayListener from "@mui/material/ClickAwayListener";
import Grow from "@mui/material/Grow";
import MenuItem from "@mui/material/MenuItem";
import MenuList from "@mui/material/MenuList";
import Paper from "@mui/material/Paper";
import Popper from "@mui/material/Popper";
import React from "react";

/**
 * @typedef StateMachine
 * @property {string} name
 * @property {string} currentState
 * @property {Array<{name: string, label: string, url: string}>} availableProcessing
 */

/**
 * @param {StateMachine} machine
 * @param {function(object): void} onProcessed Called after the URL has been
 * @param {object=} btnProps Mapping of machine states, to props for the button.
 *   Used to style button variants, mostly.
 * @param {object=} eventStyles Mapping of event names, to styles ('sx') for the menu item.
 *   Used to style button colors, mostly.
 * @param {string=} href If given, the href for the dropdown button.
 * @param {object=} sx
 * @param {boolean=} disablePortal Passed to Popper's disablePortal.
 *   Might be needed if the component is within a card,
 *   depending on how it measures available room to pop.
 */
export default function StateMachineProcessor({
  machine,
  onProcessed,
  href,
  btnProps = {},
  eventStyles = {},
  sx,
  disablePortal,
}) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const toggle = useToggle();
  const anchorRef = React.useRef(null);

  const handleMenuItemClick = (event, url) => {
    api
      .post(url)
      .then((r) => onProcessed(r.data))
      .catch(enqueueErrorSnackbar)
      .finally(toggle.turnOff);
    toggle.turnOff();
  };

  const handleClose = (event) => {
    if (anchorRef.current && anchorRef.current.contains(event.target)) {
      return;
    }
    toggle.turnOff();
  };

  const bprops = {
    size: "small",
    variant: "contained",
    ...btnProps[machine.currentState],
    sx,
  };

  return (
    <>
      <ButtonGroup {...bprops} ref={anchorRef}>
        <Button component={Link} href={href} sx={{ display: "flex", flex: 1 }}>
          {machine.currentState}
        </Button>
        <Button
          size="small"
          disabled={machine.availableProcessing.length === 0}
          onClick={toggle.toggle}
        >
          <ArrowRightIcon />
        </Button>
      </ButtonGroup>
      <Popper
        sx={{ zIndex: 1 }}
        open={toggle.isOn}
        anchorEl={anchorRef.current}
        role={undefined}
        transition
        disablePortal={disablePortal}
        placement="bottom-start"
      >
        {({ TransitionProps }) => (
          <Grow
            {...TransitionProps}
            style={{
              transformOrigin: "center top",
            }}
          >
            <Paper>
              <ClickAwayListener onClickAway={handleClose}>
                <MenuList id="split-button-menu" autoFocusItem>
                  {machine.availableProcessing.map(({ name, label, url }) => (
                    <MenuItem
                      key={name}
                      sx={{ ...eventStyles[name] }}
                      onClick={(event) => handleMenuItemClick(event, url)}
                    >
                      <ArrowRightIcon />
                      {label}
                    </MenuItem>
                  ))}
                </MenuList>
              </ClickAwayListener>
            </Paper>
          </Grow>
        )}
      </Popper>
    </>
  );
}
