import { formatPhoneNumber, numberToUs } from "./numberFormatter";

describe("typing number", () => {
  it("only formats numbers", () => {
    expect(formatPhoneNumber("e", "")).toEqual("");
    expect(formatPhoneNumber("+", "")).toEqual("");
    expect(formatPhoneNumber(" ", "")).toEqual("");
  });
  it("returns empty string when numbers start with 1 and 0", () => {
    expect(formatPhoneNumber("1", "")).toEqual("");
    expect(formatPhoneNumber("0", "")).toEqual("");
  });
  it("formats phone number", () => {
    expect(formatPhoneNumber("222", "22")).toEqual("222");
    expect(formatPhoneNumber("(222) 3", "(222)")).toEqual("(222) 3");
    expect(formatPhoneNumber("(222) 3334", "(222) 333")).toEqual("(222) 333-4");
    expect(formatPhoneNumber("(222) 333-4444", "(222) 333-444")).toEqual(
      "(222) 333-4444"
    );
  });
  it("converts formatted number to US region", () => {
    expect(numberToUs(formatPhoneNumber("(222) 333-4444"))).toEqual("+12223334444");
  });
  it("can format US region number", () => {
    expect(formatPhoneNumber("+12223334444")).toEqual("(222) 333-4444");
  });
  it("formats number without previousNumber parameter", () => {
    expect(formatPhoneNumber("2223334444")).toEqual("(222) 333-4444");
  });
});

describe("deleting number", () => {
  it("formats phone number", () => {
    expect(formatPhoneNumber("(222) 333-444", "(222) 333-4444")).toEqual("(222) 333-444");
    expect(formatPhoneNumber("(222) 333-", "(222) 333-4")).toEqual("(222) 333");
    expect(formatPhoneNumber("(222) ", "(222) 3")).toEqual("222");
    expect(formatPhoneNumber("22", "222")).toEqual("22");
  });
});
