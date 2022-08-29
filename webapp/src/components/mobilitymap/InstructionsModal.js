import api from "../../api";
import { t } from "../../localization";
import useToggle from "../../shared/react/useToggle";
import React from "react";
import Accordion from "react-bootstrap/Accordion";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";
import Modal from "react-bootstrap/Modal";

const InstructionsModal = () => {
  const showModal = useToggle(false);
  const [accordionKey, setAccordionKey] = React.useState("");
  const [version, setVersion] = React.useState("");
  React.useEffect(() => {
    if (!accordionKey) {
      api.getUserAgent().then((r) => {
        if (r.data) {
          const browser = r.data;
          if (browser.device === "Uknown") {
            return;
          }
          if (browser.isIos) {
            setAccordionKey("ios");
            return;
          }
          if (browser.isAndroid) {
            setVersion(browser.platformVersion);
            setAccordionKey("android");
            return;
          }
          setAccordionKey(browser.device.toLowerCase());
        }
      });
    }
  }, [accordionKey]);

  return (
    <>
      <Alert variant="warning" className="m-0">
        <i className="bi bi-exclamation-triangle-fill"></i>{" "}
        {t("errors:denied_geolocation")}
      </Alert>
      <Button
        variant="success"
        size="sm"
        className="w-100 mt-3 fs-6"
        onClick={showModal.toggle}
      >
        <i className="bi bi-book"></i> Location Instructions
      </Button>
      <Modal show={showModal.isOn} onHide={showModal.toggle}>
        <Modal.Header closeButton>
          <Modal.Title>Enable Location Services</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Alert variant="info">
            <p>
              <i className="bi bi-info-circle-fill"></i> Click on your browser/device
              below and follow the instructions to enable location service.
            </p>
            <p className="m-0">
              <b>Refresh</b> this page after you are done following instructions.
            </p>
          </Alert>
          <Accordion defaultActiveKey={accordionKey}>
            <Accordion.Item eventKey="chrome">
              <Accordion.Header>Google Chrome</Accordion.Header>
              <Accordion.Body>
                <ol>
                  <li>
                    Open Chrome and click the <b>three-dotted menu</b> in the top
                    right-hand corner followed by <b>Settings</b>
                  </li>
                  <li>
                    On the Settings page, click <b>Privacy and security</b> from the
                    left-hand menu followed by <b>Site Settings</b>
                  </li>
                  <li>
                    Scroll down and click <b>Location</b>
                  </li>
                  <li>
                    You can then toggle the <b>Ask before accessing (recommend)</b> option
                    to enable location services
                  </li>
                </ol>
              </Accordion.Body>
            </Accordion.Item>
            <Accordion.Item eventKey="firefox">
              <Accordion.Header>Mozilla Firefox</Accordion.Header>
              <Accordion.Body>
                <ol>
                  <li>
                    Click on <b>Menu</b> in the top right-hand corner followed by{" "}
                    <b>Settings</b>
                  </li>
                  <li>
                    Scroll down to <b>Permissions</b> section and click on <b>Settings</b>{" "}
                    next to Location
                  </li>
                </ol>
                <ul>
                  <li>
                    Make sure that the status next to this website shows <b>Allowed</b>
                  </li>
                  <li>
                    Make sure <b>Block new requests asking to access your location</b> is{" "}
                    <u>unchecked</u>
                  </li>
                </ul>
                <ol>
                  <li value="3">
                    Click <b>Save Changes</b>
                  </li>
                </ol>
              </Accordion.Body>
            </Accordion.Item>
            <Accordion.Item eventKey="safari">
              <Accordion.Header>Safari</Accordion.Header>
              <Accordion.Body>
                <ol>
                  <li>
                    Start by clicking the <b>Apple</b> symbol in the upper left-hand
                    corner followed by <b>System Preferences</b>
                  </li>
                  <li>
                    Then click <b>Security &#38; Privacy</b>
                  </li>
                  <li>
                    Then click the <b>Privacy</b> tab:
                  </li>
                  <li>
                    Click on the padlock in the bottom left-hand corner of the window. You
                    will be asked to authenticate by entering your computer ID/password.
                    Once entered, you will then be able to adjust your Location Services
                    by checking the box next to <b>Enable Location Services</b> and
                    ensuring location services are enabled specifically for <b>Safari</b>
                  </li>
                  <li>Click the lock again once done</li>
                </ol>
              </Accordion.Body>
            </Accordion.Item>
            <Accordion.Item eventKey="microsoft edge">
              <Accordion.Header>Microsoft Edge</Accordion.Header>
              <Accordion.Body>
                <ol>
                  <li>
                    Start by clicking the <b>three-dotted menu</b> located in the top
                    right-hand corner of Microsoft Edge followed by <b>Settings</b>
                  </li>
                  <li>
                    Once on the settings page, click <b>Site permission</b> from the
                    left-hand menu followed by <b>Location</b>
                  </li>
                  <li>
                    You can then toggle the <b>Ask before accessing (recommended)</b>{" "}
                    option
                  </li>
                </ol>
              </Accordion.Body>
            </Accordion.Item>
            <Accordion.Item eventKey="android">
              <Accordion.Header>Android Device</Accordion.Header>
              <Accordion.Body>
                {version && (
                  <Alert variant="info">
                    <i className="bi bi-info-circle-fill"></i> We detected that you are
                    using version {version}
                  </Alert>
                )}
                <h5>Android 10 and 11</h5>
                <ol>
                  <li>Swipe down from the top of the screen.</li>
                  <li>
                    Click on the <b>location icon</b> and make sure it is illuminated blue
                    (turned on).
                  </li>
                </ol>
                <p>Alternatively:</p>
                <ol>
                  <li>
                    Go to <b>Settings &#62; Location</b>
                  </li>
                  <li>Make sure that Location is turned on</li>
                </ol>
                <h5>Android 9</h5>
                <ol>
                  <li>Open your device&#39;s Settings app</li>
                  <li>
                    Tap <b>Security &amp; Location</b> &gt; <b>Location.</b>
                    <ul>
                      <li>
                        If you have a work profile, tap <b>Advanced.</b>
                      </li>
                    </ul>
                  </li>
                  <li>
                    <b>Turn Location on</b>: Tap <b>Location.</b>
                  </li>
                </ol>
                <h5>Android 4.4 to 8.1</h5>
                <ol>
                  <li>Open your phone&#39;s Settings app.</li>
                  <li>
                    Tap <b>Security &amp; Location</b>. If you don&#39;t see &#34;Security
                    &amp; Location,&#34; tap <b>Location</b>.
                  </li>
                  <li>
                    Tap <b>Mode</b>. Then pick:
                  </li>
                </ol>
                <ul>
                  <li>
                    <b>High accuracy:</b> Use GPS, Wi-Fi, mobile networks, and sensors to
                    get the most accurate location. Use Google Location Services to help
                    estimate your phone&#39;s location faster and more accurately.
                  </li>
                  <li>
                    <b>Battery saving:</b> Use sources that use less battery, like Wi-Fi
                    and mobile networks. Use Google Location Services to help estimate
                    your phone&#39;s location faster and more accurately.
                  </li>
                  <li>
                    <b>Device only:</b> Use only GPS. Don&#39;t use Google Location
                    Services to provide location information. This can estimate your
                    phone&#39;s location more slowly and use more battery.
                  </li>
                </ul>
                <h5>Android 4.1 to 4.3</h5>
                <ol>
                  <li>Open your phone&#39;s Settings app.</li>
                  <li>
                    Under &#34;Personal&#34;, tap <b>Location access</b>.
                  </li>
                  <li>
                    At the top of the screen, turn <b>Access to my location</b> on
                  </li>
                </ol>
              </Accordion.Body>
            </Accordion.Item>
            <Accordion.Item eventKey="ios">
              <Accordion.Header>IOS Device</Accordion.Header>
              <Accordion.Body>
                <ol>
                  <li>
                    Go to <b>Settings &#62; Privacy &#62; Location Services</b>
                  </li>
                  <li>
                    Make sure that <b>Location Services</b> is turned on
                  </li>
                </ol>
              </Accordion.Body>
            </Accordion.Item>
          </Accordion>
          <div className="d-flex justify-content-end mt-2">
            <Button variant="primary" className="mt-2" onClick={showModal.toggle}>
              Close
            </Button>
          </div>
        </Modal.Body>
      </Modal>
    </>
  );
};

export default InstructionsModal;
