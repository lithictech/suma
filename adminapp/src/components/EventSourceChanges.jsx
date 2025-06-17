import config from "../config";
import { Logger } from "../shared/logger";
import useMountEffect from "../shared/react/useMountEffect";
import CachedIcon from "@mui/icons-material/Cached";
import { Button } from "@mui/material";
import React from "react";

const logger = new Logger("sse");

/**
 * Button that appears when there are events reported from an EventSource
 * (Server Side Events).
 * @param eventsUrl URL to subscribe to.
 * @param eventsToken Usually the Suma-Events-Token header value on a response.
 * @param As Defaults to Button component.
 * @param onClick Called when the button is clicked. Should usually refetch the resources.
 * @constructor
 */
export default function EventSourceChanges({ eventsUrl, eventsToken, As, onClick }) {
  As = As || Button;
  const counter = React.useRef(0);
  const counterButton = React.useRef(null);
  const counterSpan = React.useRef(null);
  const eventSource = React.useRef(null);

  const handleMessage = React.useCallback(() => {
    counter.current += 1;
    if (counterSpan.current) {
      counterButton.current.style.visibility = "visible";
      counterSpan.current.innerText = `${counter.current} changes`;
    }
  }, []);

  const handleError = React.useCallback(() => {}, []);

  useMountEffect(() => {
    eventSource.current = createEventSource({
      eventsUrl,
      eventsToken,
      onMessage: handleMessage,
      onError: handleError,
    });
    return () => {
      logger.debug("closing");
      eventSource.current.close();
    };
  });

  function handleChangesClick(e) {
    e.preventDefault();
    counter.current = 0;
    counterButton.current.style.visibility = "hidden";
    onClick();
  }

  return (
    <As ref={counterButton} sx={{ visibility: "hidden" }} onClick={handleChangesClick}>
      <span ref={counterSpan} />
      <CachedIcon sx={{ marginLeft: 1 }} />
    </As>
  );
}

function createEventSource({ eventsUrl, eventsToken, onMessage, onError }) {
  const es = new EventSource(`${config.apiHost}${eventsUrl}?token=${eventsToken}`);
  logger.debug("opened_eventsource");
  es.onmessage = function (e) {
    logger.debug("received_event", { message: e.data });
    onMessage(es, e);
  };
  es.onerror = function (e) {
    // Note that a CORS error with status code null will be seen during rapid mount/unmount,
    // like React strict mode. Nothing we can do.
    logger.info("events_errored");
    es.close();
    onError(es, e);
  };
  return es;
}
