import api from "../api";
import scooterContainer from "../assets/images/scooter-container.svg";
import config from "../config";
import { t } from "../localization";
import { localStorageCache } from "../shared/localStorageHelper";
import { vehicleIconForVendorService } from "./mobilityIconLookup.js";
import leaflet from "leaflet";
import "leaflet.animatedmarker/src/AnimatedMarker";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/leaflet.markercluster";
import "leaflet/dist/leaflet.css";
import isUndefined from "lodash/isUndefined";

export default class MapBuilder {
  constructor(host) {
    this.mapHost = host;
    this._l = leaflet;
    this._minZoom = 8;
    this._maxZoom = 23;
    this._zoomTo = 20;
    this._mapCache = localStorageCache.getItem("mobilityMapCache", {});
    this._saveMapCacheField = function (fields) {
      this._mapCache = { ...this._mapCache, ...fields };
      localStorageCache.setItem("mobilityMapCache", this._mapCache);
    };
    this._latOffset = 0.00004;
    this._map = this._l.map(this.mapHost, {
      attributionControl: false,
      zoomControl: false,
    });
    this._map.setView(
      [this._mapCache.lat || 45.5152, this._mapCache.lng || -122.6784],
      this._mapCache.zoom || this._minZoom
    );
    this._l.control
      .zoom({
        position: "bottomright",
        zoomInTitle: t("mobility.zoom_in"),
        zoomOutTitle: t("mobility.zoom_out"),
      })
      .addTo(this._map);
    this.updateLastExtendedVehicleBounds();
    this.updateLastExtendedStaticBounds();
    this._restrictedAreasGroup = this._l.layerGroup();
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
    this._lastLocation = null;
    this._locationMarker = null;
    this._locationAccuracyCircle = null;
    this._animationTimeoutId = null;
    this._refreshId = null;
    this._clickedVehicle = null;
    this._onVehicleClick = null;
    this._onSelectedVehicleRemoved = null;
  }

  init() {
    this.setTileLayer();
    this.getAndUpdateRestrictedAreas(
      this._lastExtendedStaticBounds,
      this._restrictedAreasGroup
    );
    this._map.addLayer(this._restrictedAreasGroup);
    return this;
  }

  setTileLayer() {
    this._l
      .tileLayer(
        `https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token=${config.mapboxAccessToken}`,
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
      this.setLocationMarkerTransition("none");
    });
    this._map.on("zoomend", () => {
      if (!this._locationAccuracyCircle || !this._locationMarker) {
        return;
      }
      this._animationTimeoutId = setTimeout(() => {
        this._locationAccuracyCircle._path.classList.add(
          "mobility-location-accuracy-circle-transition"
        );
        this.setLocationMarkerTransition("all 1000ms linear 0s");
      }, 250);
    });
  }

  setLocationMarkerTransition(value) {
    const el = this._locationMarker.getElement();
    if (!el) {
      // Leaflet can fire its event though the DOM element is gone by the time
      // the zoomstart/zoomend callback is actually called.
      // To reproduce, load the map and then go to a different tab.
      return;
    }
    el.style.transition = value;
  }

  setMapEventHandlers() {
    this._map.on("moveend", this.moveEnd, this);
    this._map.on("zoomend", this.zoomEnd, this);
    this._map.on("click", this.click, this);
  }

  moveEnd() {
    const bounds = this._map.getBounds();
    const { lat, lng } = bounds.getCenter();
    this._saveMapCacheField({ lat, lng });
    // After the move, we can be:
    // - inside the vehicle and static bounds. Noop.
    // - outside the vehicle, but inside the static bounds. Update vehicle bounds, request new vehicles.
    // - outside static bounds. Update both bounds and request new of both.
    let vehicleOOB, staticOOB;
    if (!this._lastExtendedStaticBounds.contains(bounds)) {
      vehicleOOB = true;
      staticOOB = true;
    } else if (!this._lastExtendedVehicleBounds.contains(bounds)) {
      vehicleOOB = true;
    }
    if (vehicleOOB) {
      this.updateLastExtendedVehicleBounds();
      this.getAndUpdateScooters(this._lastExtendedVehicleBounds, this._mcg);
    }
    if (staticOOB) {
      this.updateLastExtendedStaticBounds();
      this.getAndUpdateRestrictedAreas(
        this._lastExtendedStaticBounds,
        this._restrictedAreasGroup
      );
    }
  }

  zoomEnd() {
    this._saveMapCacheField({
      zoom: this._map.getZoom(),
    });
  }

  click() {
    if (!this._clickedVehicle) {
      return;
    }
    this._clickedVehicle = null;
    if (this._onVehicleClick) {
      this._onVehicleClick(null);
    }
  }

  /**
   * These handlers need to be set independently of any other side effects,
   * since the handler functions can change (ie via React.useCallback).
   */
  setVehicleEventHandlers({ onClick, onSelectedRemoved }) {
    this._onVehicleClick = onClick;
    this._onSelectedVehicleRemoved = onSelectedRemoved;
    return this;
  }

  loadScooters() {
    this.getAndUpdateScooters(this._lastExtendedVehicleBounds, this._mcg);
    this.setMapEventHandlers();
    this._map.addLayer(this._mcg);
  }

  getAndUpdateScooters(bounds, mcg) {
    api.getMobilityMap(boundsToParams(bounds)).then((r) => {
      this.updateScooters({ ...r, bounds, mcg });
      this._refreshId = refreshTimer(
        () => this.getAndUpdateScooters(bounds, mcg),
        r.data.refresh
      );
    });
  }

  updateScooters({ data, bounds, mcg }) {
    const precisionFactor = 1 / data.precision;
    const applicableMarkers = [];
    const allNewMarkersIds = [];
    const currentMarkers = mcg.getLayers();
    const currentMarkersIds = currentMarkers.map((marker) => marker.options.id);
    // Create new vehicle markers
    ["ebike", "escooter"].forEach((vehicleType) => {
      data[vehicleType]?.forEach((bike) => {
        const id = `${bike.p}-${bike.c[0]}-${bike.c[1]}${bike.d ? "-" + bike.d : ""}`;
        const marker = this.createVehicleMarker(
          id,
          bike,
          vehicleType,
          data.providers[bike.p],
          precisionFactor
        );
        if (!currentMarkersIds.includes(id)) {
          applicableMarkers.push(marker);
        }
        allNewMarkersIds.push(id);
      });
    });
    // Add new list of markers that are not in the current list
    mcg.addLayers(applicableMarkers, { chunkedLoading: true });

    // Remove current markers that are not in the new list or
    // current out-of-bound markers that are not in the new bounds
    const removableCurrentMarkers = currentMarkers.filter(
      (marker) =>
        !allNewMarkersIds.includes(marker.options.id) || !bounds.contains(marker._latlng)
    );
    mcg.removeLayers(removableCurrentMarkers, { chunkedLoading: true });

    // Close the map reserve card if the marker for a scooter is now gone
    const isVehicleRemoved = removableCurrentMarkers.find(
      (marker) => this._clickedVehicle?.options.id === marker.options.id
    );
    if (!this._clickedVehicle || !isVehicleRemoved) {
      // Keep the card open if we didn't have one open, or the vehicle hasn't been removed.
      return;
    }
    this._onSelectedVehicleRemoved();
    this._clickedVehicle = null;
  }

  createVehicleMarker(id, bike, vehicleType, vehicleProvider, precisionFactor) {
    // calculate lat, lng offsets when available
    let [lat, lng] = bike.c;
    if (bike.o) {
      lat += bike.o[0];
      lng += bike.o[1];
    }
    lat = lat * precisionFactor;
    lng = lng * precisionFactor;
    const vehicleImg = vehicleIconForVendorService(vehicleType, vehicleProvider.slug);
    const vehicleIcon = this._l.divIcon({
      html: `
        <img src="${scooterContainer}" alt=""/>
        <img src="${vehicleImg}" class="mobility-map-icon-img" alt=""/>
      `,
      className: "mobility-map-icon",
      iconSize: [43.4, 52.6],
      iconAnchor: [21.7, 52.6],
    });
    return this._l
      .marker([lat, lng], {
        id,
        icon: vehicleIcon,
        riseOnHover: true,
      })
      .on("click", (e) => {
        this.centerLocation(e.latlng);
        const mapVehicle = {
          loc: bike.c,
          type: vehicleType,
          disambiguator: bike.d,
          provider: vehicleProvider,
        };
        this._onVehicleClick(mapVehicle);
        this._clickedVehicle = e.target;
      });
  }

  getAndUpdateRestrictedAreas(bounds, group) {
    api
      .getMobilityMapFeatures(boundsToParams(bounds))
      .then(api.pickData)
      .then((d) => {
        this.updateRestrictedAreas({ restrictions: d.restrictions, group });
      });
  }

  updateRestrictedAreas({ restrictions, group }) {
    const currentRestrictionsIds = group.getLayers().map((layer) => layer.options.id);
    restrictions.forEach((r) => {
      const id = [r.restriction, r.bounds.ne[0], r.bounds.sw[0]].join("-");
      if (currentRestrictionsIds.includes(id)) {
        // Only create restrictions that do not currently exist
        return;
      }
      const restrictedAreaLayer = this.createRestrictedArea({
        id,
        latlngs: r.multipolygon,
        restriction: r.restriction,
      });
      if (restrictedAreaLayer) {
        group.addLayer(restrictedAreaLayer);
      }
    });
  }

  createRestrictedArea({ id, latlngs, restriction }) {
    if (!id || !latlngs || !restriction) {
      return;
    }
    const popup = this._l.popup({
      direction: "top",
      offset: [0, 10],
    });
    const parkingRestrictionContent = `<h6 class='mb-0'>${t(
      "mobility.do_not_park_title"
    )}</h6><p class='m-0'>${t("mobility.do_not_park_intro")}</p>`;
    const ridingRestrictionContent = `<h6 class='mb-0'>${t(
      "mobility.do_not_ride_title"
    )}</h6><p class='m-0'>${t("mobility.do_not_ride_intro")}</p>`;

    if (restriction.startsWith("do-not-park-or-ride")) {
      popup.setContent(parkingRestrictionContent + "<hr />" + ridingRestrictionContent);
    } else if (restriction.startsWith("do-not-park")) {
      popup.setContent(parkingRestrictionContent);
    } else if (restriction.startsWith("do-not-ride")) {
      popup.setContent(ridingRestrictionContent);
    }
    return this._l
      .polygon([latlngs], {
        id: id,
        fillOpacity: 0.25,
        color: "#b53d00",
        weight: 1,
      })
      .bindPopup(popup);
  }

  stopRefreshTimer() {
    if (!this._refreshId) {
      return;
    }
    clearInterval(this._refreshId);
    this._refreshId = null;
  }

  _getLocationZoom() {
    return Math.max(15, this._map.getZoom());
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
          this.centerLocation({
            ...this._lastLocation,
            targetZoom: this._getLocationZoom(),
          });
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
        link.title = t("mobility.locate_me");
        link.setAttribute("role", "button");
        link.setAttribute("aria-label", t("mobility.locate_me"));
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

  /**
   * @param onLocationFound {function} Called with the leaflet LocationEvent
   * @param onLocationError {function} Called with (this, {error, cachedLocation: {lat, lng} | null}
   * @returns {MapBuilder}
   */
  startTrackingLocation({ onLocationFound, onLocationError }) {
    // 'watch' is true, so "locationfound" event is called multiple times.
    // We set lastLoc and create the movement line on the first location found;
    // then we update lastLoc, and append to the movement line, on subsequent location finds.
    let lastLoc, movementLine;
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
        console.error("locationerror.", e);
        if (!ignoreLocationError()) {
          let cachedLocation = null;
          if (this._mapCache.lat) {
            cachedLocation = { lat: this._mapCache.lat, lng: this._mapCache.lng };
          }
          onLocationError(this, { error: e, cachedLocation });
        }
      })
      .on("locationfound", (location) => {
        if (!lastLoc) {
          // Add location centering button
          this.newLocateControl().addTo(this._map);
          lastLoc = location.latlng;
          movementLine = this._l.polyline([[lastLoc.lat, lastLoc.lng]]);
          this._locationMarker = this._l.animatedMarker(movementLine.getLatLngs(), {
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
          this._locationAccuracyCircle = this._l.circle([lastLoc.lat, lastLoc.lng], {
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
          if (!this._clickedVehicle) {
            // Prevent centering if vehicle is focused
            this.centerLocation({ ...lastLoc, targetZoom: this._getLocationZoom() });
          }
          onLocationFound(location);
        }
        if (
          this._locationMarker &&
          this._locationAccuracyCircle &&
          lastLoc &&
          movementLine &&
          (lastLoc.lat !== location.latitude || lastLoc.lng !== location.longitude)
        ) {
          this._locationMarker.stop();
          const nextLocation = [location.latitude, location.longitude];
          // Sets next location distance for animation purpose
          const nextDistance = this._l
            .latLng(lastLoc.lat, lastLoc.lng)
            .distanceTo(nextLocation);
          this._locationMarker.options.distance = nextDistance;
          movementLine.addLatLng(nextLocation);
          this._locationAccuracyCircle
            .setLatLng(nextLocation)
            .setRadius(location.accuracy);
          this._locationMarker.start();
          lastLoc = location.latlng;
          this._lastLocation = location.latlng;

          onLocationFound(location);
        }
      });
    return this;
  }

  beginTrip() {
    // will be re-enabled when loading scooters again
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
    targetZoom = isUndefined(targetZoom) ? 18 : targetZoom;
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

  updateLastExtendedVehicleBounds() {
    let b = this._map.getBounds();
    b = b.pad(1);
    this._lastExtendedVehicleBounds = b;
  }

  updateLastExtendedStaticBounds() {
    const b = this._map.getBounds();
    // Use a large area here since this doesn't change often and is cached.
    // We want to capture the entire market.
    const staticDegreesPad = 1;
    b._northEast.lat += staticDegreesPad;
    b._northEast.lng += staticDegreesPad;
    b._southWest.lat -= staticDegreesPad;
    b._southWest.lng -= staticDegreesPad;
    this._lastExtendedStaticBounds = b;
  }
}

function boundsToParams(bounds) {
  const { _northEast, _southWest } = bounds;
  return {
    sw: [_southWest.lat, _southWest.lng],
    ne: [_northEast.lat, _northEast.lng],
  };
}

const refreshTimer = (function () {
  let timer = 0;
  // Because the inner function is bound to the refreshTimer variable,
  // it will remain in scope and will allow the timer variable to be manipulated
  return function (cb, ms) {
    clearTimeout(timer);
    timer = setInterval(cb, ms);
    return timer;
  };
})();
