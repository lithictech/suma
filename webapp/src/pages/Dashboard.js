import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import Navbar from "react-bootstrap/Navbar";
import Nav from "react-bootstrap/Nav";
import Container from "react-bootstrap/Container";
import { Link } from "react-router-dom";
import sumaLogo from "../assets/images/suma-logo.png";

const Dashboard = () => {
  const { user } = useUser();
  return (
    <div className="mainContainer">
      <Navbar className="p-3 border-bottom">
        <Navbar.Brand href="/dashboard" className="me-auto d-flex align-items-center" style={{color: "#A77948"}}>
          <img
            alt="MySuma logo"
            src={sumaLogo}
            width="50"
            className="d-inline-block align-top me-2"
          />{' '}
          MySuma Overview
        </Navbar.Brand>
        <Nav>
          <Nav.Link href="#deets">
            Settings {" "}
            <i className="bi bi-gear-fill" role="img" aria-label="Settings Icon"></i>
          </Nav.Link>
        </Nav>
      </Navbar>
      <Navbar bg="light" variant="light" className="justify-content-end p-3">
        <p className="m-0">Balance: $30</p>
      </Navbar>
      <Container>
        <Row>
          <Col className="px-3 py-4">
            {user.ongoingTrip && 
            <Link to="/map" className="btn btn-sm btn-success w-100 p-2 my-2" style={{ borderRadius: "50px"}}>
              <i className="bi bi-map" role="img" aria-label="Map Icon"></i> {" "}
              You have an active ride in mobility map.
            </Link>
            }
            <Link to="/map" className="btn btn-sm btn-light w-100 p-2 my-2" style={{border: "2px solid #6597F8", borderRadius: "50px"}}>
            Scooter Service
            </Link>
            <Link to="/map" className="btn btn-sm btn-light w-100 p-2 my-2" style={{border: "2px solid #6597F8", borderRadius: "50px"}}>
            Food Service
            </Link>
            <Link to="/map" className="btn btn-sm btn-light w-100 p-2 my-2" style={{border: "2px solid #6597F8", borderRadius: "50px"}}>
            Other Services
            </Link>
            <Button variant="danger" size="small" className="w-100 p-2 my-2" style={{ borderRadius: "50px"}} onClick={signOut}>
              Log Out
            </Button>
          </Col>
        </Row>

      </Container>
    </div>
  );
};

export default Dashboard;
