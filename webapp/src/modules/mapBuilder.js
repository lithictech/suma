import api from "../api";
import scooterIcon from "../assets/images/kick-scooter.png";
import scooterContainer from "../assets/images/scooter-container.svg";
import { t } from "../localization";
import leaflet from "leaflet";
import "leaflet.animatedmarker/src/AnimatedMarker";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/leaflet.markercluster";
import "leaflet/dist/leaflet.css";
import _ from "lodash";

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
    this._map = this._l
      .map(this.mapRef.current)
      .setView([this._dLat, this._dLng], this._minZoom);
    this._lastBounds = this._map.getBounds();
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
    this._scooterIcon = this._l.divIcon({
      html: `<img src="${scooterContainer}" alt="scooter container"/><img src="${scooterIcon}" class="mobility-map-icon-img" alt="scooter icon"/>`,
      className: "mobility-map-icon",
      iconSize: [43.4, 52.6],
      iconAnchor: [21.7, 52.6],
    });
    this._vehicleClicked = false;
    this._locationMarker = null;
    this._locationAccuracyCircle = null;
    this._animationTimeoutId = null;
    this._refreshId = null;
    this._onVehicleClick = null;
  }

  init() {
    this.setTileLayer();
    this.setLocationEventHandlers();
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

  setLocationEventHandlers() {
    this._map.on("zoomstart", () => {
      if (this._locationAccuracyCircle && this._locationMarker) {
        // prevent animation issues when zooming
        if (this._animationTimeoutId) {
          clearTimeout(this._animationTimeoutId);
          this._animationTimeoutId = null;
        }
        this._locationAccuracyCircle._path.classList.remove(
          "mobility-location-accuracy-circle-animation"
        );
        this._locationMarker._icon.style.transition = "none";
      }
    });
    this._map.on("zoomend", () => {
      if (this._locationAccuracyCircle && this._locationMarker) {
        this._animationTimeoutId = setTimeout(() => {
          this._locationAccuracyCircle._path.classList.add(
            "mobility-location-accuracy-circle-animation"
          );
          this._locationMarker._icon.style.transition = "all 1000ms linear 0s";
        }, 250);
      }
    });
  }

  setVehicleEventHandlers() {
    this._map.on("moveend", this.moveEnd, this);
    this._map.on("click", this.click, this);
  }

  moveEnd() {
    if (!this._map) {
      return;
    }
    const bounds = this._map.getBounds();
    if (
      !this._lastBounds.contains(bounds._northEast) ||
      !this._lastBounds.contains(bounds._southWest)
    ) {
      this._lastBounds = bounds;
      this.getScooters(bounds);
    }
  }

  click() {
    if (this._vehicleClicked) {
      this._onVehicleClick(null);
      this._vehicleClicked = false;
    }
  }

  loadScooters({ onVehicleClick }) {
    this._onVehicleClick = onVehicleClick;
    this.getScooters(this._lastBounds);
    this.setVehicleEventHandlers();
    this._map.addLayer(this._mcg);
    return this;
  }

  getScooters(bounds) {
    const { _northEast, _southWest } = bounds;
    api
      .getMobilityMap({
        minloc: [_southWest.lat, _southWest.lng],
        maxloc: [_northEast.lat, _northEast.lng],
      })
      .then((r) => {
        const precisionFactor = 1 / r.data.precision;
        const newMarkers = [];
        this.removeVisibleLayers(bounds);
        ["ebike", "escooter"].forEach((vehicleType) => {
          r.data[vehicleType]?.forEach((bike) => {
            const marker = this.newMarker(
              bike,
              vehicleType,
              r.data.providers,
              precisionFactor
            );
            newMarkers.push(marker);
          });
        });
        this._mcg.addLayers(newMarkers, { chunkedLoading: true });
        this.stopRefreshTimer().startRefreshTimer(r.data.refresh);
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

  startRefreshTimer(interval) {
    if (!this._refreshId && !this._ongoingTrip) {
      this._refreshId = window.setInterval(() => {
        this.getScooters(this._lastBounds);
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
  removeVisibleLayers(bounds) {
    const removableMarkers = [];
    this._mcg.eachLayer((marker) => {
      if (bounds.contains(marker._latlng)) {
        removableMarkers.push(marker);
      }
    });
    this._mcg.removeLayers(removableMarkers);
  }

  newMarker(bike, vehicleType, providers, precisionFactor) {
    const [lat, lng] = bike.c;
    return this._l
      .marker([lat * precisionFactor, lng * precisionFactor], {
        icon: this._scooterIcon,
        riseOnHover: true,
      })
      .on("click", (e) => {
        this.centerLocation(e.latlng);
        const mapVehicle = {
          loc: bike.c,
          type: vehicleType,
          disambiguator: bike.d,
          providerId: providers[bike.p].id,
        };
        this._onVehicleClick(mapVehicle);
        this._vehicleClicked = true;
      });
  }

  startTrackingLocation({ onGetLocation, onGetLocationError }) {
    let loc, line;
    this._map
      .locate({
        watch: true,
        maxZoom: this._zoomTo,
        timeout: 20000,
        enableHighAccuracy: true,
      })
      .on("locationerror", (e) => {
        /**
         * Error code 3 is for timeout but location service keeps attempting
         * and seems to always prevail so there's no need for throwing geolocation error msg.
         */
        function ignoreLocationError() {
          const ERR_LOCATION_PERMISSION_DENIED = 1;
          const ERR_LOCATION_POSITION_UNAVAILABLE = 2;
          return (
            e.code !== ERR_LOCATION_PERMISSION_DENIED &&
            e.code !== ERR_LOCATION_POSITION_UNAVAILABLE
          );
        }
        if (!ignoreLocationError()) {
          onGetLocationError();
        }
      })
      .on("locationfound", (location) => {
        if (!loc) {
          loc = location.latlng;
          line = this._l.polyline([[loc.lat, loc.lng]]);
          this._locationMarker = this._l.animatedMarker(line.getLatLngs(), {
            icon: this._l.divIcon({
              html: "<div class='mobility-location-marker-icon'></div>",
              iconSize: [16, 16],
              iconAnchor: [8, 8],
            }),
            interactive: false,
            autoStart: false,
            duration: 250,
            distance: 0,
          });
          this._locationAccuracyCircle = this._l.circle([loc.lat, loc.lng], {
            className: "mobility-location-accuracy-circle-animation",
            radius: location.accuracy,
            color: "#0495ff",
            fillColor: "#0495ff",
            fillOpacity: 0.1,
            weight: 0,
          });
          this._map.addLayer(this._locationAccuracyCircle);
          this._map.addLayer(this._locationMarker);
          this.centerLocation({ ...loc, targetZoom: 15 });
          onGetLocation(location);
        }
        if (
          this._locationMarker &&
          this._locationAccuracyCircle &&
          loc &&
          line &&
          (loc.lat !== location.latitude || loc.lng !== location.longitude)
        ) {
          this._locationMarker.stop();
          const nextLocation = [location.latitude, location.longitude];
          // Sets next location distance for animation purpose
          const nextDistance = this._l.latLng(loc.lat, loc.lng).distanceTo(nextLocation);
          this._locationMarker.options.distance = nextDistance;
          line.addLatLng(nextLocation);
          this._locationAccuracyCircle
            .setLatLng(nextLocation)
            .setRadius(location.accuracy);
          this._locationMarker.start();
          loc = location.latlng;
          onGetLocation(location);
        }
      });
    return this;
  }

  beginTrip() {
    // will be re-enabled on getScooters
    this._map.off("moveend", this.moveEnd, this);
    this._map.off("click", this.click, this);
    this._mcg.clearLayers();
    this.stopRefreshTimer();
    if (this._locationMarker) {
      this.centerLocation(this._locationMarker.getLatLng());
    }
  }

  centerLocation({ lat, lng, targetZoom }) {
    lat = Number(lat);
    lng = Number(lng);
    targetZoom = _.isUndefined(targetZoom) ? 18 : targetZoom;
    const loweredLat = lat + this._latOffset;
    const { lat: mLat, lng: mLng } = this._map.getCenter();
    if (
      mLat.toPrecision(7) !== loweredLat.toPrecision(7) ||
      mLng.toPrecision(7) !== lng.toPrecision(7)
    ) {
      this._map.flyTo([loweredLat, lng], targetZoom, {
        animate: true,
        duration: 1.3,
        easeLinearity: 1,
      });
    }
  }

  unmount() {
    this.stopRefreshTimer();
    this._map.stopLocate();
  }
}
