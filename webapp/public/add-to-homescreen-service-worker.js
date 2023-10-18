/* eslint-disable-next-line */
const selfInstance = self;
selfInstance.addEventListener('install', event => {
  // Required for the browser to detect the app as installable,
  // figured out by manual testing.
  event.waitUntil(Promise.resolve());
});

selfInstance.addEventListener('activate', event => {
  // Adopt open pages owned by the previous service worker
  // once this one is running.
  event.waitUntil(selfInstance.clients.claim());
});

selfInstance.addEventListener('fetch', event => {
  // Required for the browser to detect the app as installable
  // https://www.simicart.com/blog/pwa-add-to-home-screen/
  event.waitUntil(Promise.resolve());
});