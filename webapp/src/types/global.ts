declare global {
  type RequireOnlyOne<T, Keys extends keyof T = keyof T> = Pick<
    T,
    Exclude<keyof T, Keys>
  > &
    {
      [K in Keys]-?: Required<Pick<T, K>> & Partial<Record<Exclude<Keys, K>, never>>;
    }[Keys];

  type KeysOfType<KT, T> = {
    [K in keyof T]: T[K] extends KT ? K : never;
  }[keyof T];

  type StringKeys<T> = KeysOfType<string, T>;
}

export {};
