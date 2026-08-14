import clsx from "clsx";
import React from "react";

interface DrawerTitleProps extends React.HTMLAttributes<HTMLHeadingElement> {
  className?: string;
}

export default function DrawerTitle({ className, ...rest }: DrawerTitleProps) {
  return <h5 className={clsx(className, "mb-0")} {...rest} />;
}
