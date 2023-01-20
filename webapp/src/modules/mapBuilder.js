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
  constructor(host) {
    this.mapHost = host;
    this._l = leaflet;
    this._minZoom = 13;
    this._maxZoom = 23;
    this._zoomTo = 20;
    this._dLat = 45.5152;
    this._dLng = -122.6784;
    this._latOffset = 0.00004;
    this._map = this._l.map(this.mapHost, { zoomControl: false });
    this._map.setView([this._dLat, this._dLng], this._minZoom);
    this._l.control
      .zoom({
        position: "bottomright",
        zoomInTitle: t("mobility:zoom_in"),
        zoomOutTitle: t("mobility:zoom_out"),
      })
      .addTo(this._map);
    this.newLocateControl().addTo(this._map);
    this._lastExtendedBounds = expandBounds(this._map.getBounds());
    this._mcg = this._l.markerClusterGroup({
      spiderfyOnMaxZoom: false,
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
    this._lastLocation = null;
    this._locationMarker = null;
    this._locationAccuracyCircle = null;
    this._animationTimeoutId = null;
    this._refreshId = null;
    this._vehicleClicked = null;
    this._onVehicleClick = null;
    this._onVehicleRemove = null;
  }

  init() {
    this.setTileLayer();
    this.loadGeoFences(this._lastExtendedBounds);
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
    // prevent animation issues when zooming
    this._map.on("zoomstart", () => {
      if (!this._locationAccuracyCircle || !this._locationMarker) {
        return;
      }
      if (this._animationTimeoutId) {
        clearTimeout(this._animationTimeoutId);
        this._animationTimeoutId = null;
      }
      this._locationAccuracyCircle._path.classList.remove(
        "mobility-location-accuracy-circle-transition"
      );
      this._locationMarker.getElement().style.transition = "none";
    });
    this._map.on("zoomend", () => {
      if (!this._locationAccuracyCircle || !this._locationMarker) {
        return;
      }
      this._animationTimeoutId = setTimeout(() => {
        this._locationAccuracyCircle._path.classList.add(
          "mobility-location-accuracy-circle-transition"
        );
        this._locationMarker.getElement().style.transition = "all 1000ms linear 0s";
      }, 250);
    });
  }

  setVehicleEventHandlers() {
    this._map.on("moveend", this.moveEnd, this);
    this._map.on("click", this.click, this);
  }

  moveEnd() {
    const bounds = this._map.getBounds();
    if (this._lastExtendedBounds.contains(bounds)) {
      return;
    }
    this._lastExtendedBounds = expandBounds(bounds);
    this.getAndUpdateScooters(this._lastExtendedBounds, this._mcg);
  }

  click() {
    if (!this._vehicleClicked) {
      return;
    }
    this._onVehicleClick(null);
    this._vehicleClicked = null;
  }

  loadScooters({ onVehicleClick, onVehicleRemove }) {
    this._onVehicleClick = onVehicleClick;
    this._onVehicleRemove = onVehicleRemove;
    this.getAndUpdateScooters(this._lastExtendedBounds, this._mcg);
    this.setVehicleEventHandlers();
    this._map.addLayer(this._mcg);
    return this;
  }

  getAndUpdateScooters(bounds, mcg) {
    api.getMobilityMap(boundsToParams(bounds)).then((r) => {
      this.updateScooters({ ...r, bounds, mcg });
      this.stopRefreshTimer().startRefreshTimer(r.data.refresh, bounds, mcg);
    });
  }

  updateScooters({ data, bounds, mcg }) {
    const precisionFactor = 1 / data.precision;
    const applicableMarkers = [];
    const allNewMarkersIds = [];
    const leftoverMarkers = [];
    // First: Removes markers that are not present in the bounds
    const removableMarkers = mcg
      .getLayers()
      .filter((marker) => !bounds.contains(marker._latlng));
    mcg.removeLayers(removableMarkers, { chunkedLoading: true });
    // Second: Add markers for ids that are missing
    const currentMarkersIds = mcg.getLayers().map((marker) => marker.options.id);
    ["ebike", "escooter"].forEach((vehicleType) => {
      data[vehicleType]?.forEach((bike) => {
        const id = `${bike.p}-${bike.c[0]}-${bike.c[1]}${bike.d ? "-" + bike.d : ""}`;
        const marker = this.newMarker(
          id,
          bike,
          vehicleType,
          data.providers,
          precisionFactor
        );
        if (!currentMarkersIds.includes(id)) {
          applicableMarkers.push(marker);
        } else {
          leftoverMarkers.push(marker);
        }
        allNewMarkersIds.push(id);
      });
    });
    mcg.addLayers(applicableMarkers, { chunkedLoading: true });
    // Third: Remove *leftover* markers that are not present in the new list of ids
    // Leftover markers are visible in new bounds but might not exist in new list of ids,
    // therefor we should remove the non-existing leftover marker(s)
    const removableLeftoverMarkers = leftoverMarkers.filter(
      (marker) => !allNewMarkersIds.includes(marker.options.id)
    );
    mcg.removeLayers(removableLeftoverMarkers, { chunkedLoading: true });

    // Fourth: Close the map reserve card if the marker for a scooter is now gone
    const removedMarkers = removableMarkers.concat(removableLeftoverMarkers);
    const isVehicleRemoved = removedMarkers.find(
      (marker) => this._vehicleClicked?.options.id === marker.options.id
    );
    if (!this._vehicleClicked || !isVehicleRemoved) {
      return;
    }
    this._onVehicleRemove();
    this._vehicleClicked = null;
  }

  loadGeoFences(bounds) {
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
    const popup = this._l.popup({
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

    if (restriction.startsWith("do-not-park-or-ride")) {
      popup.setContent(parkingRestrictionContent + "<hr />" + ridingRestrictionContent);
    } else if (restriction.startsWith("do-not-park")) {
      popup.setContent(parkingRestrictionContent);
    } else if (restriction.startsWith("do-not-ride")) {
      popup.setContent(ridingRestrictionContent);
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

  startRefreshTimer(interval, bounds, mcg) {
    if (this._refreshId) {
      return;
    }
    this._refreshId = window.setInterval(() => {
      this.getAndUpdateScooters(bounds, mcg);
    }, interval);
  }

  stopRefreshTimer() {
    if (!this._refreshId) {
      return this;
    }
    clearInterval(this._refreshId);
    this._refreshId = null;
    return this;
  }

  newMarker(id, bike, vehicleType, providers, precisionFactor) {
    // calculate lat, lng offsets when available
    let [lat, lng] = bike.c;
    if (bike.o) {
      lat += bike.o[0];
      lng += bike.o[1];
    }
    lat = lat * precisionFactor;
    lng = lng * precisionFactor;
    return this._l
      .marker([lat, lng], {
        id,
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
        this._vehicleClicked = e.target;
      });
  }

  newLocateControl() {
    // Adds locate button to center map on location when clicked
    const LocateControl = this._l.Control.extend({
      options: {
        position: "bottomright",
        link: undefined,
        center: (e) => {
          e.preventDefault();
          if (!this._lastLocation) {
            return;
          }
          this.centerLocation({ ...this._lastLocation, targetZoom: 15 });
        },
      },
      onAdd() {
        const container = leaflet.DomUtil.create(
          "div",
          "leaflet-control-locate leaflet-bar leaflet-control"
        );
        const link = leaflet.DomUtil.create(
          "a",
          "leaflet-bar-part leaflet-bar-part-single",
          container
        );
        this.options.link = link;
        link.href = "#";
        link.title = t("mobility:locate_me");
        link.setAttribute("role", "button");
        link.setAttribute("aria-label", t("mobility:locate_me"));
        leaflet.DomUtil.create("div", "bi bi-geo-fill", link);
        leaflet.DomEvent.on(
          this.options.link,
          "click",
          (e) => this.options.center(e),
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
          (e) => this.options.center(e),
          this
        );
        leaflet.DomEvent.off(this.options.link, "dblclick", (ev) => {
          leaflet.DomEvent.stopPropagation(ev);
        });
      },
    });
    return new LocateControl();
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
            className: "mobility-location-accuracy-circle-transition",
            radius: location.accuracy,
            color: "#0495ff",
            fillColor: "#0495ff",
            fillOpacity: 0.1,
            weight: 0,
          });
          this._map.addLayer(this._locationAccuracyCircle);
          this._map.addLayer(this._locationMarker);
          this._lastLocation = location.latlng;
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
    this._map.off();
    this._map.remove();
  }
}

function boundsToParams(bounds) {
  const { _northEast, _southWest } = bounds;
  return {
    sw: [_southWest.lat, _southWest.lng],
    ne: [_northEast.lat, _northEast.lng],
  };
}

function expandBounds(bounds, distance) {
  const distanceFromMapsCenter = (bounds.getEast() - bounds.getWest()) / 2;
  distance = distance || distanceFromMapsCenter;
  bounds._northEast.lat += distance;
  bounds._northEast.lng += distance;
  bounds._southWest.lat -= distance;
  bounds._southWest.lng -= distance;
  return bounds;
}
