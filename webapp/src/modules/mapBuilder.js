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
    this._lastLocation = null;
    this._locationMarker = null;
    this._locationAccuracyCircle = null;
    this._animationTimeoutId = null;
    this._refreshId = null;
    this._onVehicleClick = null;
  }

  init() {
    this.setTileLayer();
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
    api.getMobilityMap(boundsToParams(bounds)).then((r) => {
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
    // TODO: Need to use new bounds logic
    const bounds = this._l.latLngBounds(
      this._l.latLng(45.40706339656264, -122.80156150460245),
      this._l.latLng(45.58041884450583, -122.51986645843971)
    );
    return api.getMobilityMapFeatures(boundsToParams(bounds)).then((d) => {
      d.data.restrictions.forEach((r) => {
        this.createRestrictedArea({
          latlngs: r.polygon,
          restriction: r.restriction,
        });
      });
    });
  }

  createRestrictedArea({ latlngs, restriction }) {
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
    if (restriction === "do-not-park") {
      popup.setContent(parkingRestrictionContent);
      polygonFillOpacity = 0.2;
    }
    if (restriction === "do-not-ride") {
      popup.setContent(ridingRestrictionContent);
      polygonFillOpacity = 0.2;
    }
    if (restriction === "do-not-park-or-ride") {
      popup.setContent(allRestrictionsContent);
    }
    const restrictedIcon = this._l.divIcon({
      iconAnchor: [12, 12],
      iconSize: [24, 24],
      className: "mobility-restricted-area-icon",
      html: "<i class='bi bi-slash-circle'></i>",
    });

    const restrictedMarker = this._l
      .marker(this._l.latLngBounds(latlngs).getCenter(), {
        icon: restrictedIcon,
      })
      .bindPopup(popup)
      .addTo(this._map);
    this._l
      .polygon([latlngs], {
        fillOpacity: polygonFillOpacity,
        color: "#b53d00",
        weight: 1,
      })
      .on("click", () => {
        restrictedMarker.openPopup();
      })
      .addTo(this._map);
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

  setLocateControl() {
    const LocateControl = this._l.Control.extend({
      options: {
        position: "topleft",
        link: undefined,
        center: () => {
          this.centerLocation({ ...this._lastLocation, targetZoom: 15 });
        },
      },
      onAdd() {
        const container = leaflet.DomUtil.create(
          "div",
          "leaflet-control-locate leaflet-bar leaflet-control"
        );
        const layer = new leaflet.LayerGroup();
        layer.addTo(this._map);
        const link = leaflet.DomUtil.create(
          "a",
          "leaflet-bar-part leaflet-bar-part-single",
          container
        );
        this.options.link = link;
        link.href = "#";
        link.title = "Locate me";
        link.setAttribute("role", "button");
        leaflet.DomUtil.create("div", "bi bi-geo-fill", link);

        leaflet.DomEvent.on(
          this.options.link,
          "click",
          () => this.options.center(),
          this
        );
        leaflet.DomEvent.on(this.options.link, "dblclick", (ev) => {
          leaflet.DomEvent.stopPropagation(ev);
        });
        return container;
      },
      onRemove() {
        leaflet.DomEvent.off(
          this.options.link,
          "click",
          () => this.options.center(),
          this
        );
        leaflet.DomEvent.off(this.options.link, "dblclick", (ev) => {
          leaflet.DomEvent.stopPropagation(ev);
        });
      },
    });

    this._l.control.locate = () => new LocateControl();
    this._l.control.locate().addTo(this._map);
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
              className: "mobility-location-marker-icon",
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
          this._lastLocation = location.latlng;
          this.setLocateControl();
          this.setLocationEventHandlers();
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
          this._lastLocation = location.latlng;

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

function boundsToParams(bounds) {
  const { _northEast, _southWest } = bounds;
  return {
    sw: [_southWest.lat, _southWest.lng],
    ne: [_northEast.lat, _northEast.lng],
  };
}
