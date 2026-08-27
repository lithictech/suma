import Link, { LinkProps } from "../routing/Link";
import "./DivLink.css";
import clsx from "clsx";


export default function DivLink({className, ...rest}: LinkProps) {
  
  return <Link className={clsx('div-link', className)}  {...rest} />
}