export function formatUsRegionPhoneNumber(num) {
  if (!num) {
    return "";
  }
  return "+" + num.toString().replace(/(\d)(\d\d\d)(\d\d\d)(\d\d\d\d)/, "$1 $2 $3 $4");
}
