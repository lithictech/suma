import MapBuilder from "../../modules/mapBuilder";
import ReservationCard from "./ReservationCard";
import React from "react";

const Map = () => {
  const mapRef = React.useRef();
  React.useEffect(() => {
    if (!mapRef.current) {
      return;
    }
    new MapBuilder(mapRef).init();
  }, []);
  return (
    <div className="position-relative">
      <div ref={mapRef} />
      <ReservationCard />
    </div>
  );
};

export default Map;
