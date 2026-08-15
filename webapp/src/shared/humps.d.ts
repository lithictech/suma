declare module "humps" {
  interface HumpsOptions {
    separator?: string;
    split?: RegExp;
    process?: (
      key: string,
      convert: (key: string, options?: HumpsOptions) => string,
      options?: HumpsOptions
    ) => string;
  }

  const humps: {
    camelize: (str: string, options?: HumpsOptions) => string;
    decamelize: (str: string, options?: HumpsOptions) => string;
    pascalize: (str: string, options?: HumpsOptions) => string;
    depascalize: (str: string, options?: HumpsOptions) => string;
    camelizeKeys: <T = Record<string, any>>(object: T, options?: HumpsOptions) => T;
    decamelizeKeys: <T = Record<string, any>>(object: T, options?: HumpsOptions) => T;
    pascalizeKeys: <T = Record<string, any>>(object: T, options?: HumpsOptions) => T;
    depascalizeKeys: <T = Record<string, any>>(object: T, options?: HumpsOptions) => T;
  };
  export default humps;
}
