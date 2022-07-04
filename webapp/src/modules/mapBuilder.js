import api from "../api";
import scooterIcon from "../assets/images/kick-scooter.png";
import scooterContainer from "../assets/images/scooter-container.svg";
import leaflet from "leaflet";
import "leaflet.animatedmarker/src/AnimatedMarker";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/leaflet.markercluster";
import "leaflet/dist/leaflet.css";

export default class MapBuilder {
  constructor(mapRef) {
    this.mapRef = mapRef;
    this._l = leaflet;
    this._minZoom = 13;
    this._maxZoom = 20;
    this._dLat = 45.5152;
    this._dLng = -122.6784;
    this._latOffset = 0.00004;
    this._map = null;
    this._mcg = null;
    this._scooterIcon = null;
    this._lastBounds = null;
    this._vehicleClicked = false;
    this._tripMarker = null;
    this._refreshId = null;
  }

  init() {
    this._map = this._l
      .map(this.mapRef.current)
      .setView([this._dLat, this._dLng], this._minZoom);
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
          maxZoom: this._maxZoom,
          minZoom: this._minZoom,
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
      html: `<img src="${scooterContainer}" alt="scooter container"/><img src="${scooterIcon}" class="mobility-map-icon-img" alt="scooter icon"/>`,
      className: "mobility-map-icon",
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
          className: "mobility-map-cluster-icon",
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
        this.stopRefreshTimer();
        this.startRefreshTimer(r.data.refresh, onVehicleClick);
      });
  }

  startRefreshTimer(interval, onVehicleClick) {
    if (!this._refreshId && !this._ongoingTrip) {
      this._refreshId = window.setInterval(() => {
        this.getScooters(onVehicleClick);
      }, interval);
    }
  }

  stopRefreshTimer() {
    if (this._refreshId) {
      clearInterval(this._refreshId);
      this._refreshId = null;
    }
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
          this._map.flyTo([e.latlng.lat + this._latOffset, e.latlng.lng], 18, {
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

  /**
   * Error code 3 is for timeout but location service keeps attempting
   * and seems to always prevail so there's no need for throwing geolocation error msg.
   */
  ignoreLocationError(e) {
    const ERR_LOCATION_PERMISSION_DENIED = 1;
    const ERR_LOCATION_POSITION_UNAVAILABLE = 2;
    return (
      e.code !== ERR_LOCATION_PERMISSION_DENIED &&
      e.code !== ERR_LOCATION_POSITION_UNAVAILABLE
    );
  }

  beginTrip({ onGetLocation, onGetLocationError }) {
    this.tripMode();
    let loc, line;
    this._map
      .locate({
        watch: true,
        maxZoom: this._maxZoom,
        timeout: 20000,
        enableHighAccuracy: true,
      })
      .on("locationerror", (e) => {
        if (!this.ignoreLocationError(e)) {
          onGetLocationError();
        }
      })
      .on("locationfound", (e) => {
        if (!loc) {
          loc = e.latlng;
          this._mcg.clearLayers();
          this._map.setView([e.latitude + this._latOffset, e.longitude], this._maxZoom);
          line = this._l.polyline([[e.latlng.lat, e.latlng.lng]]);
          this._tripMarker = this._l.animatedMarker(line.getLatLngs(), {
            icon: this._scooterIcon,
            autoStart: false,
            duration: 250,
            distance: 0,
          });
          this._map.addLayer(this._tripMarker);
          onGetLocation(e);
        }
        if (
          this._tripMarker &&
          loc &&
          line &&
          (loc.lat !== e.latitude || loc.lng !== e.longitude)
        ) {
          this._tripMarker.stop();
          // Sets next location distance for animation purpose
          const nextDistance = this._l
            .latLng(loc.lat, loc.lng)
            .distanceTo([e.latitude, e.longitude]);
          this._tripMarker.options.distance = nextDistance;
          line.addLatLng([e.latitude, e.longitude]);
          this._tripMarker.start();
          this._map.flyTo([e.latitude + this._latOffset, e.longitude], this._maxZoom, {
            animate: true,
            duration: 0.25,
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
    this.stopRefreshTimer();
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

  unmount() {
    this.stopRefreshTimer();
    this._map.stopLocate();
  }
}
