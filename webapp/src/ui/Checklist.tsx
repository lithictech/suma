import Card from "./Card";
import CardBody from "./CardBody";
import "./Checklist.css";
import Stack from "./Stack";
import React from "react";

export default function Checklist({ children }: { children?: React.ReactNode }) {
  return (
    <Card>
      <CardBody>
        <Stack gap={3} direction="vertical">
          {children}
        </Stack>
      </CardBody>
    </Card>
  );
}
