import { encodeUrlJson, decodeUrlJson } from "./urlJsonEncoder";

it("round trips json", () => {
  expect(encodeUrlJson({ x: 1 })).toEqual("eyJ4IjoxfQ%3D%3D");
  expect(decodeUrlJson(encodeUrlJson({ x: 1 }))).toEqual({ x: 1 });
});
