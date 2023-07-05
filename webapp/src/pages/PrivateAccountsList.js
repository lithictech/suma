import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import SumaMarkdown from "../components/SumaMarkdown";
import { t } from "../localization";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Modal from "react-bootstrap/Modal";

export default function PrivateAccountsList() {
  const {
    state: accounts,
    replaceState: replaceAccounts,
    loading: accountsLoading,
    error: accountsError,
  } = useAsyncFetch(api.getPrivateAccounts, {
    default: {},
    pickData: true,
  });

  const [error, setError] = useError();
  const [viewAccount, setViewAccount] = React.useState(null);

  const screenLoader = useScreenLoader();

  if (error || accountsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (accountsLoading) {
    return <PageLoader />;
  }
  const handleConfigure = (o) => {
    screenLoader.turnOn();
    api
      .configurePrivateAccount({ id: o.id })
      .then((r) => {
        const { allVendorAccounts, ...rest } = r.data;
        console.log(accounts);
        console.log(r.data);
        replaceAccounts({ items: allVendorAccounts });
        setViewAccount(rest);
      })
      .catch((e) => setError(e))
      .finally(screenLoader.turnOff);
  };

  const handleHelp = (o) => {
    setViewAccount(o);
  };

  return (
    <>
      <LayoutContainer top>
        <LinearBreadcrumbs back="/dashboard" />
        <h2>Private Accounts</h2>
        <p className="text-secondary">
          Used to hide your email and phone number from vendors you use through the Suma
          platform. Please follow the instructions for the vendors you want to create a
          private account with.
        </p>
      </LayoutContainer>
      <hr />
      <Modal show={!!viewAccount} onHide={() => setViewAccount(null)}>
        <Modal.Header closeButton>
          <Modal.Title>{viewAccount?.vendorName} Private Accounts</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <div className="mt-4 d-flex justify-content-center align-items-center flex-column">
            <ScrollTopOnMount />
            <div className="mt-2 mx-2">
              <SumaMarkdown>{viewAccount?.instructions}</SumaMarkdown>
            </div>
            <div className="d-flex justify-content-end mt-2">
              <Button
                variant="outline-primary"
                className="mt-2"
                onClick={() => setViewAccount(null)}
              >
                {t("common:close")}
              </Button>
            </div>
          </div>
        </Modal.Body>
      </Modal>
      {!isEmpty(accounts.items) && (
        <LayoutContainer>
          <Stack gap={3}>
            {accounts.items.map((a) => (
              <Card key={a.id} className="p-0">
                <Card.Body className="px-2 pb-4">
                  <PrivateAccount
                    account={a}
                    onConfigure={() => handleConfigure(a)}
                    onHelp={() => handleHelp(a)}
                  />
                </Card.Body>
              </Card>
            ))}
          </Stack>
        </LayoutContainer>
      )}
      {isEmpty(accounts.items) && (
        <LayoutContainer>
          <p>
            It looks like no vendors are set up for Private Accounts. Contact your
            administrator for more information.
          </p>
        </LayoutContainer>
      )}
    </>
  );
}

function PrivateAccount({ account, onConfigure, onHelp }) {
  const { email, emailRequired, vendorImage, vendorName } = account;
  return (
    <Stack direction="vertical">
      <Stack direction="horizontal">
        <SumaImage
          image={vendorImage}
          width={150}
          params={{ crop: "none", fmt: "jpeg", flatten: [255, 255, 255] }}
        />
        <h2 className="ms-2 my-0">{vendorName}</h2>
      </Stack>
      {emailRequired ? (
        <>
          <Button onClick={onConfigure}>Set up a new email</Button>
        </>
      ) : (
        <>
          <p>Using email: {email}</p>
          <Button onClick={() => onHelp()}>Help</Button>{" "}
        </>
      )}
    </Stack>
  );
}
