const externalLinks = {
  safeHosts: ["https://mysuma.org"],
  mobilityInfoLink: "https://mysuma.org/sumaplatform#mobility",
  privacyPolicy: "https://app.mysuma.org/privacy-policy",
  sumaIntroLink: "https://mysuma.org/",
  android: (lang) =>
    `https://support.google.com/chrome/answer/142065?hl=${lang}&co=GENIE.Platform%3DAndroid&oco=1`,
  chrome: (lang) =>
    `https://support.google.com/chrome/answer/142065?hl=${lang}&co=GENIE.Platform%3DDesktop&oco=1`,
  edge: (lang) =>
    `https://support.microsoft.com/${lang}-us/windows/windows-location-service-and-privacy-3a8eee0a-5b0b-dc07-eede-2a5ca1c49088`,
  firefox: (lang) =>
    `https://support.mozilla.org/${lang}-US/kb/does-firefox-share-my-location-websites`,
  ios: (lang) => `https://support.apple.com/${lang}-us/HT207092`,
  safari: (lang) =>
    `https://support.apple.com/${lang}-${lang}/guide/mac-help/allow-apps-to-detect-the-location-of-your-mac-mh35873/mac#:~:text=${
      lang === "en"
        ? "Specify%20which%20apps%20and%20system%20services%20can%20use%20Location%20Services"
        : "Especificar%20qué%20apps%20y%20servicios%20del%20sistema%20pueden%20usar%20Localización"
    }`,
};

export default externalLinks;
