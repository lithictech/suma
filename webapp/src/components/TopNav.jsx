import sumaLogo from "../assets/images/suma-logo-plain-128.png";
import { t } from "../localization";
import useI18Next from "../localization/useI18Next";
import signOut from "../modules/signOut";
import useBackendGlobals from "../state/useBackendGlobals";
import useGlobalViewState from "../state/useGlobalViewState";
import useOnlineStatus from "../state/useOnlineStatus";
import useUser from "../state/useUser";
import ExternalLink from "./ExternalLink";
import RLink from "./RLink";
import clsx from "clsx";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import ButtonGroup from "react-bootstrap/ButtonGroup";
import Container from "react-bootstrap/Container";
import Navbar from "react-bootstrap/Navbar";
import { Link, useLocation } from "react-router-dom";

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
      <Navbar.Collapse className="navbar-collapse nav-collapse">
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
              {userAuthed ? (
                <AuthedUserButtons
                  user={user}
                  className="mt-3"
                  onCollapse={() => setExpanded(false)}
                />
              ) : (
                <LanguageButtons className="mt-3" />
              )}
              <NavFooter className="mt-4" />
            </div>
          </div>
        </Container>
      </Navbar.Collapse>
    </Navbar>
  );
}

function LanguageButtons({ className }) {
  const { supportedLocales } = useBackendGlobals();
  const { changeLanguage } = useI18Next();
  if (!supportedLocales.items) {
    return null;
  }
  return (
    <ButtonGroup vertical className={clsx("nav-lang-btn-group", className)}>
      {supportedLocales.items.map(({ code, native }) => (
        <Button
          key={code}
          variant="outline-primary"
          className={clsx(i18next.language === code && "active-outline-button")}
          onClick={() => changeLanguage(code)}
        >
          {native}
        </Button>
      ))}
    </ButtonGroup>
  );
}

function AuthedUserButtons({ className, user, onCollapse }) {
  return (
    <>
      <NavLinkButton
        href="/dashboard"
        icon="house-door-fill"
        label={t("titles:dashboard")}
        className={className}
        onNoChangeClick={onCollapse}
      />
      {user.showPrivateAccounts && (
        <NavLinkButton
          href="/private-accounts"
          icon="incognito"
          label={t("titles:private_accounts")}
          onNoChangeClick={onCollapse}
        />
      )}
      <NavLinkButton
        href="/funding"
        icon="wallet-fill"
        label={t("payments:payment_methods")}
        onNoChangeClick={onCollapse}
      />
      <NavLinkButton
        href="/ledgers"
        icon="clock-history"
        label={t("payments:ledger_transactions")}
        onNoChangeClick={onCollapse}
      />
      <NavLinkButton
        href="/preferences"
        icon="gear-fill"
        label={t("titles:preferences")}
        onNoChangeClick={onCollapse}
      />
      <Button
        onClick={signOut}
        variant="outline-danger"
        className="nav-menu-button text-start mt-2"
      >
        <i className="bi bi-box-arrow-right me-2"></i>
        {t("common:logout")}
      </Button>
      <LanguageButtons className="mt-3" />
    </>
  );
}

function NavLinkButton({ href, className, icon, label, onNoChangeClick }) {
  const location = useLocation();
  const isAtHref = href === location.pathname;
  function handleClick(e) {
    if (isAtHref) {
      e.preventDefault();
      onNoChangeClick();
    }
  }
  const hereIcon = isAtHref ? (
    <i className="bi bi-caret-right-fill me-2"></i>
  ) : (
    <i className="bi bi-caret-right me-2"></i>
  );
  return (
    <Button
      href={href}
      variant="outline-primary"
      className={clsx("nav-menu-button text-start d-flex align-items-center", className)}
      as={RLink}
      onClick={handleClick}
    >
      {hereIcon}
      <i className={`me-2 bi bi-${icon}`} style={{ fontSize: "120%" }}></i>
      {label}
    </Button>
  );
}

function NavFooter({ className }) {
  const rowCls = "mb-1 text-center";
  const linkCls = "text-decoration-none";
  const iconStyle = { fontSize: "140%" };
  return (
    <>
      <div className={clsx("d-flex flex-column", className)}>
        <div className={clsx("text-primary", rowCls)}>
          &copy; {new Date().getFullYear()} mysuma.org
        </div>
        <div className="d-flex flex-row justify-content-center">
          <ExternalLink href="https://www.instagram.com/mysuma/">
            <i className="bi bi-instagram me-3" style={iconStyle}></i>
          </ExternalLink>
          <ExternalLink href="https://www.linkedin.com/company/mysuma/">
            <i className="bi bi-linkedin" style={iconStyle}></i>
          </ExternalLink>
        </div>
      </div>
      <div className={rowCls}>
        <Link to="/terms-of-use" className={linkCls}>
          {t("common:terms_of_use")}
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
