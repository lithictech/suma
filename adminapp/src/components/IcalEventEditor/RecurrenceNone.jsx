import useMountEffect from "../../shared/react/useMountEffect";
import { icalRruleState } from "./icalconstants";

export default function RecurrenceNone({ onChange }) {
  useMountEffect(() => onChange(icalRruleState()));
  return null;
}
