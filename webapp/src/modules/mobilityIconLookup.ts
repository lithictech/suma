import biketownEbikeIcon from "../assets/images/biketown-ebike.png";
import limeEscooterIcon from "../assets/images/lime-escooter.png";

/**
 * Build a map of vehicle type to vendor service internal name.
 * If we add more services, we need to adjust this map.
 * This isn't ideal, because it ties built assets to dynamic data in the database,
 * but it avoids having to serve images from the backend for vehicle icons.
 * This is significant in terms of network issues, so we'll take the tradeoff for now.
 * But in the future, we may need to move to having the vendor service store a reference
 * to an image, so these icons can be loaded dynamically.
 */
const iconNameLookup: Record<string, Record<string, string>> = {
  ebike: {
    biketown: biketownEbikeIcon,
  },
  escooter: {
    lime: limeEscooterIcon,
  },
};

// TODO: Create generic icons
const defaultIconsLookup: Record<string, string> = {
  ebike: biketownEbikeIcon,
  escooter: limeEscooterIcon,
};

const unknownVehicleIcon = limeEscooterIcon;

export function vehicleIconForVendorService(
  vehicleType: string,
  vendorServiceSlug: string
) {
  const icons = iconNameLookup[vehicleType] || {};
  return (
    icons[vendorServiceSlug] || defaultIconsLookup[vehicleType] || unknownVehicleIcon
  );
}
