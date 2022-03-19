import React from "react";
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Button from 'react-bootstrap/Button';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';

const Home = () => {
  const { t } = useTranslation();

  return (
    <Container>
      <Row className="justify-content-center">
        <Col>
          <img src="https://mysuma.org/wp-content/uploads/2020/06/finalpng-resize.png" alt="MySuma Logo"></img>
          <p>{t('welcome to suma')}</p>
          <div className="d-grid gap-2">
            <Button href="https://mysuma.org/" target="_blank" variant="outline-primary">Learn More</Button>
            <Link to="/start" className="btn btn-outline-success">Continue</Link>
          </div>
        </Col>
      </Row>
    </Container>
  );
}

export default Home;
