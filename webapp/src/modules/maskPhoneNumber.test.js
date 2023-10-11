import { maskPhoneNumber } from "./maskPhoneNumber";

it("returns empty string when value starts with 1, 0, or not a number", () => {
  expect(maskPhoneNumber("e")).toEqual("");
  expect(maskPhoneNumber("+")).toEqual("");
  expect(maskPhoneNumber(" ")).toEqual("");
  expect(maskPhoneNumber("1")).toEqual("");
  expect(maskPhoneNumber("0")).toEqual("");
});
it("formats phone number", () => {
  expect(maskPhoneNumber("222")).toEqual("222");
  expect(maskPhoneNumber("(222) 3")).toEqual("(222) 3");
  expect(maskPhoneNumber("(222) 3334")).toEqual("(222) 333-4");
  expect(maskPhoneNumber("(222) 333-4444")).toEqual("(222) 333-4444");
});
it("remove first character when formatted phone number that start with 1 or 0", () => {
  expect(maskPhoneNumber("(022)")).toEqual("22");
  expect(maskPhoneNumber("(122) 2")).toEqual("222");
  expect(maskPhoneNumber("(022) 222-2")).toEqual("(222) 222");
  expect(maskPhoneNumber("(122) 222-22")).toEqual("(222) 222-2");
});
it("can format US region number", () => {
  expect(maskPhoneNumber("+12223334444")).toEqual("(222) 333-4444");
});
