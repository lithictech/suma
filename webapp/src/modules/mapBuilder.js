import api from "../api";
import scooterIcon from "../assets/images/kick-scooter.png";
import scooterContainer from "../assets/images/scooter-container.svg";
import { t } from "../localization";
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
    this._maxZoom = 23;
    this._zoomTo = 20;
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
    this.loadGeoFences();
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
      showCoverageOnHover: false,
      maxClusterRadius: (mapZoom) => {
        // only cluster same location markers above zoom 17
        return mapZoom >= 17 ? 0 : 32;
      },
      iconCreateFunction: (cluster) => {
        return this._l.divIcon({
          html: "<b>" + cluster.getChildCount() + "</b>",
          className: "mobility-map-cluster-icon",
        });
      },
    });
  }

  loadScooters({ onVehicleClick }) {
    this.setEventHandlers(onVehicleClick).getScooters(onVehicleClick);
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
        this.stopRefreshTimer().startRefreshTimer(r.data.refresh, onVehicleClick);
      });
  }

  loadGeoFences() {
    const apiResponse = {
      doNotParkOrRide: [
        [
          [45.49584550855579, -122.68355369567871],
          [45.49576278304519, -122.68331229686737],
          [45.496168888931074, -122.68292605876921],
          [45.49607488319949, -122.68264710903166],
          [45.49703749446685, -122.68198192119598],
          [45.49724806348807, -122.68259346485138],
          [45.49600719897556, -122.68352150917053],
          [45.495977117072165, -122.6834625005722],
          [45.49584550855579, -122.68355369567871],
        ],
      ],
      doNotRide: [
        [
          [45.50015270758223, -122.68442273139952],
          [45.49948719071191, -122.68540441989899],
          [45.49901906820077, -122.68492430448532],
          [45.500212866911646, -122.68348127603531],
          [45.50048734303642, -122.68365025520323],
          [45.500530582303945, -122.68397212028502],
          [45.50015270758223, -122.68442273139952],
        ],
      ],
      doNotPark: [
        [
          [45.497545, -122.685026],
          [45.4971314, -122.68488],
          [45.497045, -122.6847],
          [45.496717, -122.684948],
          [45.49598, -122.68461],
          [45.495777, -122.684347],
          [45.495785, -122.684004],
          [45.4959169, -122.683655],
          [45.495728, -122.683194],
          [45.4960335, -122.682896],
          [45.4959827, -122.68276],
          [45.4956349, -122.682848],
          [45.4956349, -122.682496],
          [45.496185, -122.68174],
          [45.4965937, -122.68137],
          [45.497022, -122.681212],
          [45.4971051, -122.681268],
          [45.497308, -122.681343],
          [45.497797, -122.682384],
          [45.49768, -122.68306],
          [45.4979512, -122.683435],
          [45.4978, -122.683945],
          [45.497481, -122.684344],
          [45.49751, -122.6846],
          [45.4976071, -122.68474],
          [45.497545, -122.685026],
        ],
        [
          [45.50206179495491, -122.68491994589567],
          [45.50153071609439, -122.68461316823958],
          [45.501344602317154, -122.68466949462892],
          [45.50120172667681, -122.68466010689735],
          [45.500931013942854, -122.68455684185028],
          [45.500531522287645, -122.68468961119653],
          [45.50026456628402, -122.68468961119653],
          [45.50019312713877, -122.68461316823958],
          [45.500535282222344, -122.68412500619888],
          [45.50083513620411, -122.68403112888336],
          [45.50136340171654, -122.68418535590172],
          [45.501996937805096, -122.68425107002257],
          [45.50212665203002, -122.68437042832375],
          [45.50216613021309, -122.6845595240593],
          [45.50206179495491, -122.68491994589567],
        ],
      ],
    };
    Promise.resolve(apiResponse).then((r) => {
      if (r.doNotPark) {
        this.createRestrictedArea({
          latlngs: r.doNotPark,
          options: { restriction: "parking" },
        });
      }
      if (r.doNotRide) {
        this.createRestrictedArea({
          latlngs: r.doNotRide,
          options: { restriction: "riding" },
        });
      }
      if (r.doNotParkOrRide) {
        this.createRestrictedArea({
          latlngs: r.doNotParkOrRide,
          options: { restriction: "all" },
        });
      }
    });
  }

  createRestrictedArea({ latlngs, options }) {
    options = options || {};
    let popup = this._l.popup({
      direction: "top",
      offset: [0, -5],
    });
    let polygonFillOpacity = 0.3;
    const parkingRestrictionContent = `<h6 class='mb-0'>${t(
      "mobility:do_not_park_title"
    )}</h6><p class='m-0'>${t("mobility:do_not_park_intro")}</p>`;
    const ridingRestrictionContent = `<h6 class='mb-0'>${t(
      "mobility:do_not_ride_title"
    )}</h6><p class='m-0'>${t("mobility:do_not_ride_intro")}</p>`;
    const allRestrictionsContent =
      parkingRestrictionContent + "<hr />" + ridingRestrictionContent;
    if (options.restriction === "parking") {
      popup.setContent(parkingRestrictionContent);
      polygonFillOpacity = 0.2;
    }
    if (options.restriction === "riding") {
      popup.setContent(ridingRestrictionContent);
      polygonFillOpacity = 0.2;
    }
    if (options.restriction === "all") {
      popup.setContent(allRestrictionsContent);
    }
    const restrictedIcon = this._l.divIcon({
      iconAnchor: [12, 12],
      iconSize: [24, 24],
      className: "mobility-restricted-area-icon",
      html: "<i class='bi bi-slash-circle'></i>",
    });

    latlngs.forEach((area) => {
      const restrictedMarker = this._l
        .marker(this._l.latLngBounds(area).getCenter(), {
          icon: restrictedIcon,
          interactive: false,
        })
        .bindPopup(popup)
        .addTo(this._map);
      this._l
        .polygon([area], {
          fillOpacity: polygonFillOpacity,
          color: "#b53d00",
          weight: 1,
        })
        .on("click", () => {
          restrictedMarker.openPopup();
        })
        .addTo(this._map);
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
    return this;
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
    this._mcg.clearLayers();
    this.tripMode();
    let loc, line;
    this._map
      .locate({
        watch: true,
        maxZoom: this._zoomTo,
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
          this._map.setView([e.latitude + this._latOffset, e.longitude], this._zoomTo);
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
          this._map.flyTo([e.latitude + this._latOffset, e.longitude], this._zoomTo, {
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
