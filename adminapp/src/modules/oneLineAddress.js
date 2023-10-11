/**
 * Joins and formats the address object into a single string. The address
 * object is usually passed as a backend entity. Based on the backend's
 * *Address#one_line_address* method.
 *
 * @param address The address object, usually passed by the backend
 * @param includeCountry Include the country code at the end
 * @returns {string}
 */
export default function oneLineAddress(address, includeCountry = true) {
  const addressParts = [
    address.address1,
    address.address2,
    address.city,
    address.stateOrProvince,
    address.postalCode,
  ];
  if (includeCountry) {
    addressParts.push(address.country.toUpperCase());
  }
  return addressParts.filter(Boolean).join(", ");
}
