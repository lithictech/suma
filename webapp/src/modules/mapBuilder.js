import api from "../api";
import scooterIcon from "../assets/images/kick-scooter.png";

export default class MapBuilder {
  constructor(mapRef) {
    this.mapRef = mapRef;
    this._dZoom = 13;
    this._dLat = 45.5152;
    this._dLng = -122.6784;
    this._l = window.L;
    this._map = null;
    this._mcg = null;
    this._scooterIcon = null;
    this._lastBounds = null;
    this._vehicleClicked = false;
    this._ongoingTrip = false;
    this._latOffset = 0.00004;
  }
  init() {
    this._map = this._l
      .map(this.mapRef.current)
      .setView([this._dLat, this._dLng], this._dZoom);
    this._lastBounds = this._map.getBounds();
    this.setTileLayer();
    this.setScooterIcon();
    this.setMarkerCluster();
    // adds all markerClusterGroup to map, no needed layer rerender
    this._map.addLayer(this._mcg);
    return this;
  }
  run({ onVehicleClick }) {
    this.getScooters(onVehicleClick);

    this._map.on("moveend", () => {
      const bounds = this._map.getBounds();
      if (
        this._lastBounds.contains(bounds._northEast) === false ||
        this._lastBounds.contains(bounds._southWest) === false
      ) {
        this._lastBounds = bounds;
        this.getScooters(onVehicleClick);
      }
    });

    this._map.on("click", () => {
      if (this._ongoingTrip) return;
      if (this._vehicleClicked) {
        onVehicleClick(null);
        this._vehicleClicked = false;
      }
    });
    return this;
  }
  beginTrip({ ongoingTrip }) {
    this._mcg.clearLayers();
    // TODO: remove all layers except the ongoing marker latlng
    // setup global tripMode clause...
  }

  loadOngoingTrip(ongoingTrip) {
    this._ongoingTrip = ongoingTrip;
    if (ongoingTrip) {
      this._map.flyTo(
        [Number(ongoingTrip.beginLat) + this._latOffset, ongoingTrip.beginLng],
        20,
        {
          animate: true,
          duration: 1.3,
          easeLinearity: 1,
        }
      );
    }
    return this;
  }

  setLatLng(latLng) {
    this._dLat = latLng[0];
    this._dLng = latLng[1];
    return this;
  }

  setTileLayer() {
    this._l
      .tileLayer(
        "https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw",
        {
          maxZoom: 20,
          minZoom: 13,
          tileSize: 512,
          zoomOffset: -1,
          attribution:
            'Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, ' +
            'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
          id: "mapbox/streets-v11",
        }
      )
      .addTo(this._map);
  }

  setScooterIcon() {
    this._scooterIcon = this._l.divIcon({
      // TODO: load svg dynamically
      html: `<svg id="ePJdIXVzjGA1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 100 121.21" shape-rendering="geometricPrecision" text-rendering="geometricPrecision"><g transform="translate(-193.037537-102.389076)"><rect width="40" height="40" rx="5" ry="5" transform="matrix(.707107 0.707107-.707107 0.707107 243.037543 169.104807)" fill="#fafafa" stroke-width="0"/><rect width="100" height="100" rx="20" ry="20" transform="translate(193.037543 102.389078)" fill="#fafafa" stroke-width="0"/></g></svg>
        <img src="${scooterIcon}" class="scooterIcon"/>
      `,
      className: "scooterContainer",
      iconSize: [36, 36],
      iconAnchor: [18, 36],
    });
  }

  setMarkerCluster() {
    this._mcg = this._l.markerClusterGroup({
      spiderfyOnMaxZoom: false,
      showCoverageOnHover: false,
      removeOutsideVisibleBounds: true,
      disableClusteringAtZoom: 18,
      maxClusterRadius: 32,
      iconCreateFunction: (cluster) => {
        return this._l.divIcon({
          html: "<b>" + cluster.getChildCount() + "</b>",
          className: "scooterCluster",
        });
      },
    });
  }

  // Remove markers in visible bounds to prevent duplicates
  removeVisibleLayers() {
    const removableMarkers = [];
    this._mcg.eachLayer((marker) => {
      if (this._lastBounds.contains(marker._latlng)) {
        removableMarkers.push(marker);
      }
    });
    // removeLayers preferred over removeLayer for efficient performance
    this._mcg.removeLayers(removableMarkers);
  }

  getScooters(onVehicleClick) {
    const { _northEast, _southWest } = this._lastBounds;
    api
      .getMobilityMap({
        minloc: [_southWest.lat, _southWest.lng],
        maxloc: [_northEast.lat, _northEast.lng],
      })
      .then((r) => {
        const precisionFactor = 1 / r.data.precision;
        const newMarkers = [];
        this.removeVisibleLayers();
        ["ebike", "escooter"].forEach((vehicleType) => {
          r.data[vehicleType]?.forEach((bike) => {
            const marker = this.newMarker(
              bike,
              vehicleType,
              r.data.providers,
              precisionFactor,
              onVehicleClick
            );
            newMarkers.push(marker);
          });
        });
        // addLayers preferred over addLayer for efficient performance
        this._mcg.addLayers(newMarkers, { chunkedLoading: true });
      });
    // TODO: Handle when we click the map but not a marker, we need to deselect the vehicle
    // and hide the reservation card (call onVehicleClick(null)).
  }

  newMarker(bike, vehicleType, providers, precisionFactor, onVehicleClick) {
    const [lat, lng] = bike.c;
    return this._l
      .marker([lat * precisionFactor, lng * precisionFactor], {
        icon: this._scooterIcon,
        riseOnHover: true,
      })
      .on("click", (e) => {
        const { lat, lng } = e.latlng;
        const loweredLat = lat + this._latOffset;
        const { lat: mLat, lng: mLng } = this._map.getCenter();
        const isScooterCentered =
          mLat.toPrecision(7) === loweredLat.toPrecision(7) &&
          mLng.toPrecision(7) === lng.toPrecision(7);
        if (!this._vehicleSelected && !isScooterCentered) {
          this._map.flyTo([loweredLat, lng], 20, {
            animate: true,
            duration: 1.3,
            easeLinearity: 1,
          });
        }
        const mapVehicle = {
          loc: bike.c,
          type: vehicleType,
          disambiguator: bike.d,
          providerId: providers[bike.p].id,
        };
        onVehicleClick(mapVehicle);
        this._vehicleClicked = true;
      });
  }
}
