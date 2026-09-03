import Card from "./Card";
import CardBody from "./CardBody";
import "./Checklist.css";
import { ChecklistItemProps } from "./ChecklistItem.tsx";
import Stack from "./Stack";
import React from "react";

export interface ChecklistProps {
  children?: React.ReactNode;
}

export default function Checklist({ children }: ChecklistProps) {
  let autostep = 0;
  const kids = React.Children.map(children, (child) => {
    if (!React.isValidElement<ChecklistItemProps>(child)) {
      return child;
    }
    autostep += 1;
    return React.cloneElement(child, { autostep });
  });
  return (
    <Card>
      <CardBody>
        <Stack gap={3} direction="vertical">
          {kids}
        </Stack>
      </CardBody>
    </Card>
  );
}
