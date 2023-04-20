import { formatPhoneNumber, numberToUs } from "./numberFormatter";

it("returns empty string when value starts with 1, 0, or not a number", () => {
  expect(formatPhoneNumber("e")).toEqual("");
  expect(formatPhoneNumber("+")).toEqual("");
  expect(formatPhoneNumber(" ")).toEqual("");
  expect(formatPhoneNumber("1")).toEqual("");
  expect(formatPhoneNumber("0")).toEqual("");
});
it("formats phone number", () => {
  expect(formatPhoneNumber("222")).toEqual("222");
  expect(formatPhoneNumber("(222) 3")).toEqual("(222) 3");
  expect(formatPhoneNumber("(222) 3334")).toEqual("(222) 333-4");
  expect(formatPhoneNumber("(222) 333-4444")).toEqual("(222) 333-4444");
});
it("remove first character when formatted phone number that start with 1 or 0", () => {
  expect(formatPhoneNumber("(022)")).toEqual("22");
  expect(formatPhoneNumber("(122) 2")).toEqual("222");
  expect(formatPhoneNumber("(022) 222-2")).toEqual("(222) 222");
  expect(formatPhoneNumber("(122) 222-22")).toEqual("(222) 222-2");
});
it("converts formatted number to US region", () => {
  expect(numberToUs(formatPhoneNumber("(222) 333-4444"))).toEqual("+12223334444");
});
it("can format US region number", () => {
  expect(formatPhoneNumber("+12223334444")).toEqual("(222) 333-4444");
});
