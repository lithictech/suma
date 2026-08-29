import Nav, { NavProps } from "../ui/Nav.tsx";
import NavOption, { NavOptionProps } from "../ui/NavOption.tsx";
import HomeIcon from "@heroicons/react/24/outline/HomeIcon";
import MapIcon from "@heroicons/react/24/outline/MapIcon";
import ShoppingCartIcon from "@heroicons/react/24/outline/ShoppingCartIcon";
import SquaresPlusIcon from "@heroicons/react/24/outline/SquaresPlusIcon";
import last from "lodash/last";
import slice from "lodash/slice";
import React from "react";
import { useLocation } from "react-router-dom";

const AppNav = React.forwardRef<HTMLDivElement, NavProps>(function AppNav(props, ref) {
  const location = useLocation();
  const navOptionProps: NavOptionProps[] = [
    {
      label: "Home",
      Icon: HomeIcon,
      to: "/dashboard",
    },
    {
      label: "Offers",
      Icon: ShoppingCartIcon,
      to: "/food",
    },
    {
      label: "Map",
      Icon: MapIcon,
      to: "/mobility",
    },
    {
      label: "More",
      Icon: SquaresPlusIcon,
      to: "/menu",
    },
  ];
  slice(navOptionProps, 0, -1).forEach((o) => {
    o.active = location.pathname.startsWith(o.to as string);
  });
  last(navOptionProps)!.active = !navOptionProps.some((o) => o.active);
  return (
    <Nav ref={ref} {...props}>
      {navOptionProps.map((p) => (
        <NavOption key={p.label} {...p} />
      ))}
    </Nav>
  );
});

export default AppNav;
