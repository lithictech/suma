import sumaLogo from "../assets/images/suma-logo.png";
import React from "react";
import Nav from "react-bootstrap/Nav";
import Navbar from "react-bootstrap/Navbar";

const TopNav = () => {
  return (
    <Navbar className="p-3">
      <Navbar.Brand
        href="/dashboard"
        className="me-auto d-flex align-items-center text-primary-dark"
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
        <Nav.Link href="#todo">
          Settings <i className="bi bi-gear-fill" role="img" aria-label="Settings"></i>
        </Nav.Link>
      </Nav>
    </Navbar>
  );
};

export default TopNav;
