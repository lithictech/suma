import Nav from "../ui/Nav.tsx";
import NavOption from "../ui/NavOption.tsx";
import HomeIcon from "@heroicons/react/24/outline/HomeIcon";
import MapIcon from "@heroicons/react/24/outline/MapIcon";
import ShoppingCartIcon from "@heroicons/react/24/outline/ShoppingCartIcon";
import SquaresPlusIcon from "@heroicons/react/24/outline/SquaresPlusIcon";
import { useLocation } from "react-router-dom";

export default function AppNav() {
  const location = useLocation();
  return (
    <Nav>
      <NavOption
        label="Home"
        Icon={HomeIcon}
        to="/dashboard"
        active={location.pathname.startsWith("/dashboard")}
      />
      <NavOption
        label="Offers"
        Icon={ShoppingCartIcon}
        to="/food"
        active={location.pathname.startsWith("/food")}
      />
      <NavOption
        label="Map"
        Icon={MapIcon}
        to="/mobility"
        active={location.pathname.startsWith("/mobility")}
      />
      <NavOption
        label="More"
        Icon={SquaresPlusIcon}
        to="/food"
        active={location.pathname.startsWith("/menu")}
      />
    </Nav>
  );
}
