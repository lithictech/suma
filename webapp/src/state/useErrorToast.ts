export default function useErrorToast() {
  function f(...args: any[]) {
    // TODO: Remove.
    console.warn("useErrorToast is deprecated, use a form instead.", ...args);
  }
  return { showErrorToast: f, enqueueErrorToast: f };
}
