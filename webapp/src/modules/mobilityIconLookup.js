import biketownEbikeIcon from "../assets/images/biketown-ebike.png";
import limeEscooterIcon from "../assets/images/lime-escooter.png";
import unknownVehicleIcon from "../assets/images/loader-ring.svg";

/**
 * Build a map of vehicle type to vendor service internal name.
 * If we add more services, we need to adjust this map.
 * This isn't ideal, because it ties built assets to dynamic data in the database,
 * but it avoids having to serve images from the backend for vehicle icons.
 * This is significant in terms of network issues, so we'll take the tradeoff for now.
 * But in the future, we may need to move to having the vendor service store a reference
 * to an image, so these icons can be loaded dynamically.
 */
const iconNameLookup = {
  ebike: {
    biketown: biketownEbikeIcon,
  },
  escooter: {
    lime: limeEscooterIcon,
  },
};

// TODO: Create generic icons
const defaultIconsLookup = {
  ebike: biketownEbikeIcon,
  escooter: limeEscooterIcon,
};

export function vehicleIconForVendorService(vehicleType, vendorServiceSlug) {
  const icons = iconNameLookup[vehicleType] || {};
  return (
    icons[vendorServiceSlug] || defaultIconsLookup[vehicleType] || unknownVehicleIcon
  );
}
