import sumaLogo from "../assets/images/suma-logo.png";
import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import LanguageSwitcher from "./LanguageSwitcher";
import RLink from "./RLink";
import React from "react";
import Container from "react-bootstrap/Container";
import Nav from "react-bootstrap/Nav";
import Navbar from "react-bootstrap/Navbar";

const TopNav = () => {
  const { user, userAuthed } = useUser();
  return (
    <Navbar className="py-3" expand={false} collapseOnSelect>
      <Container>
        <Navbar.Brand
          href="/dashboard"
          className="me-auto d-flex align-items-center text-primary-dark"
          as={RLink}
        >
          <img
            alt="MySuma logo"
            src={sumaLogo}
            width="50"
            className="d-inline-block align-top me-2"
          />{" "}
          MySuma
        </Navbar.Brand>
        <Navbar.Toggle />
      </Container>
      <Navbar.Collapse
        className="px-3"
        style={{ background: "linear-gradient(0deg, rgb(240, 240, 240), transparent)" }}
      >
        <div className="d-flex justify-content-end mt-2">
          <LanguageSwitcher />
        </div>
        <Nav className="me-auto text-end">
          {user?.adminMember && (
            <Nav.Link
              className="bi bi-exclamation-circle-fill bg-danger"
              as={RLink}
              href={`/admin/member/${user.id}`}
            >
              {user.name || user.phone}
            </Nav.Link>
          )}
          {userAuthed && (
            <Nav.Link onClick={signOut}>
              Logout
              <i
                className="bi bi-box-arrow-in-right"
                role="img"
                aria-label="Logout Icon"
              ></i>
            </Nav.Link>
          )}
          <div style={{ height: "1rem" }} />
        </Nav>
      </Navbar.Collapse>
    </Navbar>
  );
};

export default TopNav;
