/**
 * There are times we may need to initialize global state just once,
 * like as part of a React mount effect. Use this to run something
 * just once ever for the page's lifetime (key is stored at module level).
 */
export default function doOnce<Args extends unknown[]>(
  key: string,
  cb: (...args: Args) => void
) {
  return (...args: Args) => {
    if (done[key]) {
      return;
    }
    cb(...args);
    done[key] = true;
  };
}

const done: Record<string, boolean> = {};
