import { t } from "../localization";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import Stack from "react-bootstrap/Stack";

const FormButtons = React.forwardRef(
  ({ primaryProps, secondaryProps, variant, back, className, style }, ref) => {
    const defaultBack = React.useCallback(() => window.history.back(), []);
    if (back) {
      secondaryProps = {
        children: t("common.back"),
        onClick: defaultBack,
      };
    }
    // Each button should be at least 1/3 of the width, leading some nice room to the sides,
    // or allowing wide button content to grow. We could move this to justify-end in some cases
    // if it looks nicer.
    const btnStyle = { minWidth: "33%" };
    variant = variant || "outline-primary";
    return (
      <div ref={ref} className={clsx("mt-4", className)} style={style}>
        <Stack gap={2} direction="horizontal" className="justify-content-center">
          {secondaryProps && (
            <Button
              variant="outline-secondary"
              className="h-100"
              style={btnStyle}
              {...secondaryProps}
            />
          )}
          {primaryProps && (
            <Button
              variant={variant}
              className="h-100"
              style={btnStyle}
              type="submit"
              {...primaryProps}
            />
          )}
        </Stack>
      </div>
    );
  }
);
export default FormButtons;
