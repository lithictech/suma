import Progress from "./Progress.tsx";
import Stack from "./Stack.tsx";
import React from "react";

interface ProgressStepHeaderProps {
  step: number;
  steps: number;
}

export default function ProgressStepHeader({ step, steps }) {
  return (
    <Stack row center gap={3}>
      <div className="flex-1">
        <Progress value={Math.ceil(((step - 1) / (steps - 1)) * 100)} />
      </div>
      <p>
        Step {step} of {steps}
      </p>
    </Stack>
  );
}
