import Payment, { PaymentCardInfo as PCI } from "./payment.js";

describe("invalidCardNumberReason", () => {
  const getreason = (x) => Payment.invalidCardNumberReason(new PCI(x, "", ""));
  it("fails a lund check", () => {
    expect(getreason("4111 1111 1111 1112")).toEqual(Payment.Invalid.FORMAT);
  });
  it("fails if the length does not match the card type", () => {
    expect(getreason("4242 4242 4242")).toEqual(Payment.Invalid.FORMAT);
  });
  it("succeeds if valid", () => {
    expect(getreason("4242424242424242")).toEqual("");
    expect(getreason("4242 4242 42 424242")).toEqual("");
  });
});

describe("parseExpiry", () => {
  const parse = Payment.parseExpiry;
  it("parses as expected", () => {
    // noinspection JSCheckFunctionSignatures
    expect(parse(null)).toBeNull();
    expect(parse("")).toBeNull();
    expect(parse("1")).toBeNull();
    expect(parse("19")).toBeNull();
    expect(parse("00")).toBeNull();
    expect(parse("12")).toEqual({ month: 12, year: null, full: false });
    expect(parse("01")).toEqual({ month: 1, year: null, full: false });
    expect(parse("00")).toBeNull();
    expect(parse("129")).toEqual({ month: 1, year: 2029, full: false });
    expect(parse("010")).toEqual({ month: 1, year: 2000, full: false });
    expect(parse("0103")).toEqual({ month: 1, year: 2003, full: true });
    expect(parse("0193")).toEqual({ month: 1, year: 2093, full: true });
    expect(parse("01931")).toEqual({ month: 1, year: 2093, full: true });
    expect(parse("01930")).toEqual({ month: 1, year: 2093, full: true });
  });
});

describe("invalidCardExpiryReason", () => {
  const getreason = (x) => Payment.invalidCardExpiryReason(new PCI("", x, ""));
  it("fails if expired", () => {
    expect(getreason("10 / 01")).toEqual(Payment.Invalid.EXPIRED);
  });
  it("fails for an invalid format", () => {
    expect(getreason("1")).toEqual(Payment.Invalid.FORMAT);
    expect(getreason("111")).toEqual(Payment.Invalid.EXPIRED);
    expect(getreason("13 / 99")).toEqual(Payment.Invalid.FORMAT);
  });
  it("succeeds if valid", () => {
    expect(getreason("11/99")).toEqual("");
    expect(getreason("1199")).toEqual("");
    expect(getreason("0199")).toEqual("");
    expect(getreason("199")).toEqual("");
    expect(getreason("1/99")).toEqual("");
  });
});

describe("invalidCardCvcReason", () => {
  const getreason = (x) =>
    Payment.invalidCardCvcReason(new PCI("4242 4242 4242 4242", "", x));
  it("fails for an invalid format", () => {
    expect(getreason("11")).toEqual(Payment.Invalid.FORMAT);
    expect(getreason("11111")).toEqual(Payment.Invalid.FORMAT);
  });
  it("succeeds if valid", () => {
    expect(getreason("199")).toEqual("");
  });
});

describe("formatCardNumber", () => {
  const fmt = (x, opts) => Payment.formatCardNumber(new PCI(x, "", ""), opts);
  it("formats a full number", () => {
    expect(fmt("4242 4242 4242 4242")).toEqual("4242 4242 4242 4242");
    expect(fmt("4242-4242-42424242")).toEqual("4242 4242 4242 4242");
    expect(fmt("378282246310005")).toEqual("3782 822463 10005");
    expect(fmt("36227206271667")).toEqual("3622 720627 1667");
    expect(fmt("6205500000000000004")).toEqual("6205 5000 0000 0000004");
  });
  it("formats a partial number", () => {
    expect(fmt("")).toEqual("");
    expect(fmt("1")).toEqual("1");
    expect(fmt("42424242")).toEqual("4242 4242");
    expect(fmt("424242424")).toEqual("4242 4242 4");
    expect(fmt("378282")).toEqual("3782 82");
  });
  it("formats a partial number with placeholder", () => {
    const opts = { placeholder: "x" };
    expect(fmt("", opts)).toEqual("xxxx xxxx xxxx xxxx");
    expect(fmt("1", opts)).toEqual("1xxx xxxx xxxx xxxx");
    expect(fmt("42424242", opts)).toEqual("4242 4242 xxxx xxxx");
    expect(fmt("424242424", opts)).toEqual("4242 4242 4xxx xxxx");
    expect(fmt("3782821", opts)).toEqual("3782 821xxx xxxxx");
  });
});

describe("formatCardExpiry", () => {
  const fmt = (x, opts) => Payment.formatCardExpiry(new PCI("", x, ""), opts);
  it("formats a full number", () => {
    expect(fmt("0123")).toEqual("01 / 23");
    expect(fmt("1223")).toEqual("12 / 23");
  });
  it("formats a partial number", () => {
    expect(fmt("")).toEqual(" / ");
    expect(fmt("1")).toEqual("1 / ");
    expect(fmt("12")).toEqual("12 / ");
    expect(fmt("138")).toEqual("13 / 8");
    expect(fmt("123")).toEqual("12 / 3");
  });
  it("formats a partial number with a placeholder", () => {
    const opts = { placeholder: "x" };
    expect(fmt("", opts)).toEqual("xx / xx");
    expect(fmt("1", opts)).toEqual("1x / xx");
    expect(fmt("12", opts)).toEqual("12 / xx");
    expect(fmt("138", opts)).toEqual("13 / 8x");
    expect(fmt("123", opts)).toEqual("12 / 3x");
  });
  it("formats a partial number using infer", () => {
    const opts = { infer: true };
    expect(fmt("", opts)).toEqual(" / ");
    expect(fmt("1", opts)).toEqual(" / ");
    expect(fmt("12", opts)).toEqual("12 / ");
    expect(fmt("138", opts)).toEqual("01 / 38");
    expect(fmt("123", opts)).toEqual("01 / 23");
    expect(fmt("1223", opts)).toEqual("12 / 23");
  });
  it("formats a partial number with a placeholder using infer", () => {
    const opts = { placeholder: "x", infer: true };
    expect(fmt("", opts)).toEqual("xx / xx");
    expect(fmt("1", opts)).toEqual("xx / xx");
    expect(fmt("12", opts)).toEqual("12 / xx");
    expect(fmt("138", opts)).toEqual("01 / 38");
    expect(fmt("123", opts)).toEqual("01 / 23");
    expect(fmt("1233", opts)).toEqual("12 / 33");
  });
});

describe("formatCardCvc", () => {
  const visa = "4242424242424242";
  const amex = "378282246310005";
  const fmt = (x, opts, number) =>
    Payment.formatCardCvc(new PCI(number || visa, "", x), opts);
  it("formats a full number", () => {
    expect(fmt("123")).toEqual("123");
    expect(fmt("1234")).toEqual("1234");
  });
  it("formats a partial number", () => {
    expect(fmt("")).toEqual("");
    expect(fmt("1")).toEqual("1");
    expect(fmt("12")).toEqual("12");
  });
  it("can use a placeholder", () => {
    const opts = { placeholder: "x" };
    expect(fmt("", opts, "_")).toEqual("xxx");
    expect(fmt("d", opts, "_")).toEqual("xxx");
    expect(fmt("", opts, visa)).toEqual("xxx");
    expect(fmt("", opts, amex)).toEqual("xxxx");
    expect(fmt("1", opts, amex)).toEqual("1xxx");
  });
});
