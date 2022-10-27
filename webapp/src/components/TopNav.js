import api from "../api";
import sumaLogo from "../assets/images/suma-logo.png";
import { t } from "../localization";
import useI18Next from "../localization/useI18Next";
import signOut from "../modules/signOut";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { useGlobalViewState } from "../state/useGlobalViewState";
import useOnlineStatus from "../state/useOnlineStatus";
import { useUser } from "../state/useUser";
import ExternalLink from "./ExternalLink";
import RLink from "./RLink";
import clsx from "clsx";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";
import Navbar from "react-bootstrap/Navbar";
import { Link } from "react-router-dom";

export default function TopNav() {
  const { isOnline } = useOnlineStatus();
  const { user, userAuthed } = useUser();
  const { setTopNav } = useGlobalViewState();
  const [expanded, setExpanded] = React.useState(false);
  return (
    <Navbar
      ref={setTopNav}
      className="pt-1 pb-0"
      bg={user?.adminMember ? "danger" : "primary"}
      expand={false}
      variant="dark"
      sticky="top"
      expanded={expanded}
      onToggle={() => setExpanded(!expanded)}
    >
      <Container>
        <Navbar.Brand
          href="/dashboard"
          className="me-auto d-flex align-items-center"
          as={RLink}
        >
          <img
            alt="MySuma logo"
            src={sumaLogo}
            width="50"
            className="d-inline-block align-top me-2"
          />{" "}
          <p className="brand-text">{t("common:app_name")}</p>
        </Navbar.Brand>
        <div
          className={clsx(
            "offline-status fs-4 ms-2 ms-auto",
            isOnline ? "opacity-0" : "offline-status-fadein"
          )}
        >
          <i className="bi bi-wifi-off text-white"></i>
        </div>

        <Navbar.Toggle className={clsx(expanded && "expanded")}>
          <div className="navbar-toggler-icon-bar" />
          <div className="navbar-toggler-icon-bar" />
          <div className="navbar-toggler-icon-bar" />
        </Navbar.Toggle>
      </Container>
      <Navbar.Collapse className="navbar-collapse">
        <Container className="mb-3">
          <div className="d-flex justify-content-end mt-2">
            <div className="d-flex flex-column">
              {user?.adminMember && (
                <Button
                  variant="danger"
                  className="mt-2"
                  href={`/admin/member/${user.id}`}
                >
                  Impersonating:
                  <br />
                  {user.name || user.phone}
                </Button>
              )}
              <LanguageButtons />
              {userAuthed && (
                <Button onClick={signOut} className="mt-5" variant="danger">
                  {t("common:logout")}
                </Button>
              )}
              <NavFooter />
            </div>
          </div>
        </Container>
      </Navbar.Collapse>
    </Navbar>
  );
}

function LanguageButtons() {
  const { state: supportedLocales } = useAsyncFetch(api.getSupportedLocales, {
    default: i18next.language,
    pickData: true,
  });
  const { changeLanguage } = useI18Next();
  if (!supportedLocales.items) {
    return null;
  }
  return supportedLocales.items.map(({ code, native }) => (
    <Button
      key={code}
      variant="outline-primary"
      className={clsx("mt-2", i18next.language === code && "active-outline-button")}
      onClick={() => changeLanguage(code)}
    >
      {native}
    </Button>
  ));
}

function NavFooter() {
  const rowCls = "mb-1 text-center";
  const linkCls = "text-decoration-none";
  const iconStyle = { fontSize: "140%" };
  return (
    <>
      <div className="d-flex flex-column mt-4">
        <div className={clsx("text-primary", rowCls)}>
          &copy; {new Date().getFullYear()} mysuma.org
        </div>
        <div className="d-flex flex-row justify-content-center">
          <ExternalLink href="https://twitter.com/sumapdx">
            <i className="bi bi-twitter me-3" style={iconStyle}></i>
          </ExternalLink>
          <ExternalLink href="https://www.linkedin.com/company/mysuma/">
            <i className="bi bi-linkedin" style={iconStyle}></i>
          </ExternalLink>
        </div>
      </div>
      <div className={rowCls}>
        <Link to="/user-agreement" className={linkCls}>
          {t("common:user_agreement")}
        </Link>
      </div>
      <div className={rowCls}>
        <Link to="/privacy-policy" className={linkCls}>
          {t("common:privacy_policy")}
        </Link>
      </div>
      <div className={rowCls}>
        <a href="mailto:apphelp@mysuma.org" className={linkCls}>
          {t("common:contact_us")}
        </a>
      </div>
    </>
  );
}
