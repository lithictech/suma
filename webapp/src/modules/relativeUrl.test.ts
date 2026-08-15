import relativeUrl from "./relativeUrl";

it("returns a relative url", () => {
  expect(relativeUrl({ location: new URL("https://foo.bar/xyz?srch=val#hval") })).toEqual(
    "/xyz?srch=val#hval"
  );
  expect(relativeUrl({ location: "https://foo.bar/xyz?srch=val#hval" })).toEqual(
    "/xyz?srch=val#hval"
  );
  expect(relativeUrl({ location: "http://x.y/xyz?srch=val#hval" })).toEqual(
    "/xyz?srch=val#hval"
  );
});
