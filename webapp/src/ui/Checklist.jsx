import Card from "./Card.jsx";
import CardBody from "./CardBody.jsx";
import "./Checklist.css";
import Stack from "./Stack.jsx";
import clsx from "clsx";
import React from "react";

export default function Checklist({ children }) {
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
