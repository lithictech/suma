export function base64encode(str) {
  const utf8Bytes = new TextEncoder().encode(str);
  const base64String = btoa(String.fromCharCode(...utf8Bytes));
  return base64String;
}

export function base64decode(base64) {
  const binaryStr = atob(base64);
  const bytes = new Uint8Array([...binaryStr].map((c) => c.charCodeAt(0)));
  return new TextDecoder().decode(bytes);
}
