import React from "react";

export default function useFrontAppSdk(chatId) {
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    if (!chatId || document.querySelector("#front-app-sdk")) {
      return;
    }
    const script = document.createElement("script");
    script.src = "https://chat-assets.frontapp.com/v1/chat.bundle.js";
    script.id = "front-app-sdk";
    document.body.appendChild(script);
    script.onload = () => {
      window.FrontChat("init", {
        chatId: chatId,
        useDefaultLauncher: true,
      });
      setLoading(false);
    };
  }, [chatId]);

  const callFront = React.useCallback((name, arg) => {
    if (!window.FrontChat) {
      return;
    }
    if (arg) {
      window.FrontChat(name, arg);
    } else {
      window.FrontChat(name);
    }
  }, []);

  return {
    loading,
    identity: (o) => callFront("identity", o),
    show: () => callFront("show", null),
    hide: () => callFront("hide", null),
  };
}
