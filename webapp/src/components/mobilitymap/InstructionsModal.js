import React from "react";
import Accordion from "react-bootstrap/Accordion";
import Button from "react-bootstrap/Button";
import Modal from "react-bootstrap/Modal";

const InstructionsModal = () => {
  const [show, setShow] = React.useState(false);
  const [accordionKey, setAccordionKey] = React.useState(null);

  const handleClose = () => setShow(false);
  const handleShow = () => {
    setAccordionKey(getBrowserName());
    setShow(true);
  };

  const getBrowserName = () => {
    const ua = navigator.userAgent;
    if (ua.match(/chrome|chromium|crios/i)) {
      return "chrome";
    } else if (ua.match(/firefox|fxios/i)) {
      return "firefox";
    } else if (ua.match(/safari/i)) {
      return "safari";
    } else if (ua.match(/edg/i)) {
      return "edge";
    } else if (ua.match(/Android/i)) {
      return "android";
    } else if (ua.match(/iPhone|iPad|iPod/i)) {
      return "ios";
    } else {
      return null;
    }
  };
  return (
    <>
      <Button variant="warning" size="sm" className=" w-100 mt-2" onClick={handleShow}>
        Location Instructions
      </Button>
      <Modal show={show} onHide={handleClose}>
        <Modal.Body>
          <p>
            <i className="bi bi-info-circle-fill text-primary"></i> Click on your
            browser/device below and follow the instructions to enable location service.
          </p>
          <p>
            <b>Reload</b> this page when you are done.
          </p>
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
            <Accordion.Item eventKey="edge">
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
              <Accordion.Header>Android Phone</Accordion.Header>
              <Accordion.Body>
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
                    <b>Turn Location on or off</b>: Tap <b>Location.</b>
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
              <Accordion.Header>IOS Phone</Accordion.Header>
              <Accordion.Body>
                <ol>
                  <li>
                    Go to <b>Settings &#62; Privacy &#62; Location Services</b>
                  </li>
                  <li>
                    Make sure that <b>Location Services</b> is on
                  </li>
                </ol>
              </Accordion.Body>
            </Accordion.Item>
          </Accordion>
          <Button variant="secondary" className="mt-2" onClick={handleClose}>
            Close
          </Button>
        </Modal.Body>
      </Modal>
    </>
  );
};

export default InstructionsModal;
