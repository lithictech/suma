import Progress from "./Progress.tsx";
import Stack from "./Stack.tsx";

interface ProgressStepHeaderProps {
  step: number;
  steps: number;
}

export default function ProgressStepHeader({ step, steps }: ProgressStepHeaderProps) {
  return (
    <Stack row center gap={3}>
      <div className="flex-1">
        <Progress value={Math.ceil((step / steps) * 100)} />
      </div>
      <p>
        Step {step} of {steps}
      </p>
    </Stack>
  );
}
