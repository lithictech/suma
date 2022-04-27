import api from "../api";
import scooterIcon from "../assets/images/kick-scooter.png";

export default class MapBuilder {
  constructor(mapRef) {
    this.mapRef = mapRef;
    this._l = window.L;
    this._dZoom = 13;
    this._dLat = 45.5152;
    this._dLng = -122.6784;
    this._latOffset = 0.00004;
    this._map = null;
    this._mcg = null;
    this._scooterIcon = null;
    this._lastBounds = null;
    this._vehicleClicked = false;
    this._tripMarker = null;
  }

  init() {
    this._map = this._l
      .map(this.mapRef.current)
      .setView([this._dLat, this._dLng], this._dZoom);
    this._lastBounds = this._map.getBounds();
    this.setTileLayer();
    this.setScooterIcon();
    this.setMarkerCluster();
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
      iconSize: [43.4, 52.6],
      iconAnchor: [21.7, 52.6],
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

  loadScooters({ onVehicleClick }) {
    this.setEventHandlers(onVehicleClick);
    this.getScooters(onVehicleClick);
    this._map.addLayer(this._mcg);
    return this;
  }

  setEventHandlers(onVehicleClick) {
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
      if (this._vehicleClicked) {
        onVehicleClick(null);
        this._vehicleClicked = false;
      }
    });
    return this;
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
        this._mcg.addLayers(newMarkers, { chunkedLoading: true });
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
    this._mcg.removeLayers(removableMarkers);
  }

  newMarker(bike, vehicleType, providers, precisionFactor, onVehicleClick) {
    const [lat, lng] = bike.c;
    return this._l
      .marker([lat * precisionFactor, lng * precisionFactor], {
        icon: this._scooterIcon,
        riseOnHover: true,
      })
      .on("click", (e) => {
        if (!this._vehicleSelected && !this.isScooterCentered(e.latlng)) {
          this._map.flyTo([e.latlng.lat + this._latOffset, e.latlng.lng], 20, {
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

  beginTrip({ onGetLocation }) {
    this.tripMode();
    let loc, line;
    this._map
      .locate({
        watch: true,
        maxZoom: 20,
        enableHighAccuracy: true,
      })
      .on("locationfound", (e) => {
        if (!loc) {
          loc = e.latlng;
          this._mcg.clearLayers();
          this._map.setView([e.latitude + this._latOffset, e.longitude], 20);
          line = this._l.polyline([[e.latlng.lat, e.latlng.lng]]);
          this._tripMarker = this._l
            .animatedMarker(line.getLatLngs(), {
              icon: this._scooterIcon,
            })
            .addTo(this._map);
          onGetLocation(e);
        }
        if (
          this._tripMarker &&
          loc &&
          line &&
          loc.lat !== e.latitude &&
          loc.lng !== e.longitude
        ) {
          line.addLatLng([e.latitude, e.longitude]);
          this._tripMarker.start();
          this._map.setView([e.latitude + this._latOffset, e.longitude], 20, {
            animate: true,
            duration: 1.0,
            easeLinearity: 1,
          });
          loc = e.latlng;
          onGetLocation(e);
        }
      });
    return this;
  }

  endTrip({ onVehicleClick }) {
    this._map.removeLayer(this._tripMarker);
    this._tripMarker = null;
    this.viewMode();
    this.loadScooters({ onVehicleClick });
  }

  tripMode() {
    // will be re-enabled on getScooters
    this._map.off("moveend click");
    this._map.dragging.disable();
    this._map.touchZoom.disable();
    this._map.doubleClickZoom.disable();
    this._map.scrollWheelZoom.disable();
    this._map.boxZoom.disable();
    this._map.keyboard.disable();
    if (this._map.tap) this._map.tap.disable();
    this._map._container.style.cursor = "default";
    return this;
  }

  viewMode() {
    this._map.stopLocate();
    this._map.dragging.enable();
    this._map.touchZoom.enable();
    this._map.doubleClickZoom.enable();
    this._map.scrollWheelZoom.enable();
    this._map.boxZoom.enable();
    this._map.keyboard.enable();
    if (this._map.tap) this._map.tap.enable();
    this._map._container.style.cursor = "grab";
  }

  isScooterCentered(latLng) {
    const lat = Number(latLng.lat);
    const lng = Number(latLng.lng);
    const loweredLat = lat + this._latOffset;
    const { lat: mLat, lng: mLng } = this._map.getCenter();
    return (
      mLat.toPrecision(7) === loweredLat.toPrecision(7) &&
      mLng.toPrecision(7) === lng.toPrecision(7)
    );
  }
}
