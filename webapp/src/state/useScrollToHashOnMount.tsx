import React from "react";
import { useLocation } from "react-router-dom";

export default function useScrollToHashOnMount() {
  const location = useLocation();

  const scrollToHash = React.useCallback(
    function scrollToHash() {
      window.setTimeout(() => scrollToHashTargetWhenReady(location.hash), 0);
    },
    [location.hash]
  );

  return scrollToHash;
}

async function scrollToHashTargetWhenReady(hash: string) {
  if (!hash) {
    return;
  }
  const id = decodeURIComponent(hash.slice(1));
  const el = document.getElementById(id);
  if (!el) {
    return;
  }

  // wait for web fonts to finish loading (common cause of late layout shift)
  if (document.fonts?.ready) {
    await document.fonts.ready;
  }

  // wait for layout to stabilize: compare position across two frames
  await waitForStableLayout(el);

  el.scrollIntoView({ behavior: "smooth", block: "start" });
}

function waitForStableLayout(el: HTMLElement, { maxFrames = 10 } = {}) {
  return new Promise<void>((resolve) => {
    let lastTop: any = null;
    let stableCount = 0;
    let frame = 0;

    function check() {
      const top = el.getBoundingClientRect().top;
      if (top === lastTop) {
        stableCount++;
      } else {
        stableCount = 0;
      }
      lastTop = top;
      frame++;

      // resolve once position hasn't changed for 2 consecutive frames,
      // or we've waited long enough that we give up and just go
      if (stableCount >= 2 || frame >= maxFrames) {
        resolve();
      } else {
        requestAnimationFrame(check);
      }
    }

    requestAnimationFrame(check);
  });
}
