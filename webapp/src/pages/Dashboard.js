import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import { useTranslation } from "react-i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Card from "react-bootstrap/Card";
import Row from "react-bootstrap/Row";
import scooterIcon from "../assets/images/kick-scooter.png";

const Dashboard = () => {
  const { user } = useUser();
  return (
    <Container>
      <Row className="justify-content-center">
        <Col>
          <h2>Member Dashboard</h2>
          <p>Welcome back.</p>
          <p>{JSON.stringify(user)}</p>
          <Button>Food Service</Button>
          <Button>Scooter Service</Button>
          <Button>Bicycle Service</Button>
          <Map />
          <Button variant="danger" onClick={signOut}>
            Log Out
          </Button>
        </Col>
      </Row>
    </Container>
  );
};

export default Dashboard;

function Map() {
  const mapRef = React.useRef();
  React.useEffect(() => {
    if (!mapRef.current) {
      return
    }
    const { L } = window;
    const map = L.map(mapRef.current).setView([45.5152, -122.6784], 13);

    L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw', {
      maxZoom: 23,
      minZoom: 12,
      tileSize: 512,
      zoomOffset: -1,
      attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, ' +
        'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
      id: 'mapbox/streets-v11',
    }).addTo(map);

    const createScooter = L.divIcon({
      // TODO: load svg dynamically
      html: `<svg id="ePJdIXVzjGA1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 100 121.21" shape-rendering="geometricPrecision" text-rendering="geometricPrecision"><g transform="translate(-193.037537-102.389076)"><rect width="40" height="40" rx="5" ry="5" transform="matrix(.707107 0.707107-.707107 0.707107 243.037543 169.104807)" fill="#fafafa" stroke-width="0"/><rect width="100" height="100" rx="20" ry="20" transform="translate(193.037543 102.389078)" fill="#fafafa" stroke-width="0"/></g></svg>
        <img src="${scooterIcon}" class="scooterIcon"/>
      `,
      className: 'scooterContainer',
      iconSize: [36, 36],
      iconAnchor: [18, 36],
    });
    const getScooters = fetch("https://gbfs.spin.pm/api/gbfs/v2_2/portland/free_bike_status");
    getScooters
      .then((r) => r.json())
      .then((response) => {
        let markers = L.markerClusterGroup({
          spiderfyOnMaxZoom: false,
          showCoverageOnHover: false,
          removeOutsideVisibleBounds: true,
          disableClusteringAtZoom: 18,
          maxClusterRadius: 32,
          iconCreateFunction: (cluster) => {
            return L.divIcon({ html: '<b>' + cluster.getChildCount() + '</b>', className: 'scooterCluster' });
          }
        });
        response.data.bikes.map((bike) => markers.addLayer(L.marker([bike.lat, bike.lon], { icon: createScooter })
          .on('click', (e) => {
            let { lat, lng } = e.latlng;
            const lowerTo = 0.00004;
            const loweredLat = lat + lowerTo;
            map.flyTo([loweredLat, lng], 21, {
              animate: true,
              duration: 1.5
            });
          })));
        map.addLayer(markers, {
          chunkInterval: 350
        });
      });

  }, [])
  return (
    <div style={{ position: 'relative' }}>
      <ReserveCard />
      <div ref={mapRef} style={{ height: '500px' }} />
    </div>
  )
}

function ReserveCard() {
  const { t } = useTranslation();
  const ride = {
    number: 3434,
    startCost: 3.00,
    costPerMinute: 0.22
  }
  return (
    <>
      {/* zIndex higher than map (400)*/}
      <Card style={{ position: 'absolute', top: 0, left: '50%', transform: 'translate(-50%, 2%)', zIndex: '401' }} className="mx-auto">
        <Card.Body>
          <Card.Title className="mb-2 text-muted">Scooter {ride.number}</Card.Title>
          <Card.Text className="text-muted">{t('scooter_cost', { startCost: ride.startCost, costPerMinute: ride.costPerMinute })}
          </Card.Text>
          <Button size="sm" variant="outline-success" href="http://google.com" onClick={(e) => e.preventDefault()}>Reserve Scooter</Button>
        </Card.Body>
      </Card>
    </>
  )
}
