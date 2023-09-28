const externalLinks = {
  safeHosts: ["https://mysuma.org"],
  mobilityInfoLink: "https://mysuma.org/sumaplatform#mobility",
  privacyPolicy: "https://app.mysuma.org/privacy-policy",
  sumaIntroLink: "https://mysuma.org/",
  edge: (lang) =>
    `https://support.microsoft.com/${lang}-us/windows/windows-location-service-and-privacy-3a8eee0a-5b0b-dc07-eede-2a5ca1c49088`,
  firefox: (lang) =>
    `https://support.mozilla.org/${lang}-US/kb/does-firefox-share-my-location-websites`,
  chrome: (lang) =>
    `https://support.google.com/chrome/answer/142065?hl=${lang}&co=GENIE.Platform%3DAndroid&oco=1`,
  android: (lang) => `https://support.google.com/accounts/answer/3467281?hl=${lang}`,
  windows: (lang) =>
    `https://support.microsoft.com/${lang}-us/windows/windows-location-service-and-privacy-3a8eee0a-5b0b-dc07-eede-2a5ca1c49088`,
  ios: (lang) =>
    `https://support.apple.com/${lang}-${lang}/guide/personal-safety/ips9bf20ad2f/web`,
  macos: (lang) =>
    `https://support.apple.com/${lang}-${lang}/guide/personal-safety/ips9bf20ad2f/web`,
};

export default externalLinks;
