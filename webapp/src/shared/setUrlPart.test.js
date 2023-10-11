import setUrlPart from "./setUrlPart";

const location = new URL("https://foo.bar/xyz?srch=val#hval");

it("replaces hash", () => {
  expect(setUrlPart({ hash: "12", location })).toEqual("https://foo.bar/xyz?srch=val#12");
  expect(setUrlPart({ hash: "", location })).toEqual("https://foo.bar/xyz?srch=val");
  expect(setUrlPart({ hash: "#12", location })).toEqual(
    "https://foo.bar/xyz?srch=val#12"
  );
});

it("replaces search", () => {
  expect(setUrlPart({ search: "x=y", location })).toEqual("https://foo.bar/xyz?x=y#hval");
  expect(setUrlPart({ search: "", location })).toEqual("https://foo.bar/xyz#hval");
  expect(setUrlPart({ search: "?x=y", location })).toEqual(
    "https://foo.bar/xyz?x=y#hval"
  );
});

it("can replace all search params", () => {
  expect(setUrlPart({ replaceParams: { x: "y" }, location })).toEqual(
    "https://foo.bar/xyz?x=y#hval"
  );
  expect(setUrlPart({ replaceParams: {}, location })).toEqual("https://foo.bar/xyz#hval");
});

it("can set search params", () => {
  expect(setUrlPart({ setParams: { srch: "y" }, location })).toEqual(
    "https://foo.bar/xyz?srch=y#hval"
  );
  expect(setUrlPart({ setParams: { srch: null }, location })).toEqual(
    "https://foo.bar/xyz#hval"
  );
  expect(setUrlPart({ setParams: { srch: "" }, location })).toEqual(
    "https://foo.bar/xyz?srch=#hval"
  );
  expect(setUrlPart({ setParams: {}, location })).toEqual(
    "https://foo.bar/xyz?srch=val#hval"
  );
});
