import { AppError } from "../modules/errors.ts";
import React from "react";

export default function useError(
  initial?: AppError
): [AppError | null, (e: AppError | null) => void] {
  const [error, setError] = React.useState<AppError | null>(initial || null);
  return [error, setError];
}
