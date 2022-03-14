import './App.css';
import Button from 'react-bootstrap/Button';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';

function App() {
  return (
    <Container>
      <Row className="justify-content-center">
        <Col>
        <img src="https://mysuma.org/wp-content/uploads/2020/06/finalpng-resize.png" alt="MySuma Logo"></img>
        <p>Welcome</p>
        <div className="d-grid gap-2">
          <Button variant="outline-primary">Learn More</Button>
          <Button variant="outline-success">Continue</Button>
        </div>
        </Col>
      </Row>
    </Container>
  );
}

export default App;
