import sumaLogo from "../assets/images/suma-logo.png";
import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import RLink from "./RLink";
import React from "react";
import Nav from "react-bootstrap/Nav";
import Navbar from "react-bootstrap/Navbar";

const TopNav = () => {
  const { user, userAuthed } = useUser();
  return (
    <Navbar className="py-3">
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
      <Nav>
        {(() => {
          if (user?.adminMember) {
            return (
              <Nav.Link
                className="bi bi-exclamation-circle-fill bg-danger"
                as={RLink}
                href={`/admin/member/${user.id}`}
              >
                {user.name || user.phone}
              </Nav.Link>
            );
          } else if (userAuthed) {
            return (
              <Nav.Link onClick={signOut}>
                Logout
                <i
                  className="bi bi-box-arrow-in-right"
                  role="img"
                  aria-label="Logout Icon"
                ></i>
              </Nav.Link>
            );
          }
          return null;
        })()}
      </Nav>
    </Navbar>
  );
};

export default TopNav;
