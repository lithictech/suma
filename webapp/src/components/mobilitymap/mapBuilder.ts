import api from "../../api";
import scooterContainer from "../../assets/images/scooter-container.svg";
import config from "../../config";
import { r, t } from "../../localization";
import { localStorageCache } from "../../modules/localStorageHelper";
import { vehicleIconForVendorService } from "../../modules/mobilityIconLookup.js";
import leaflet from "leaflet";
import * as L from "leaflet";
import "leaflet.animatedmarker/src/AnimatedMarker";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/leaflet.markercluster";
import "leaflet/dist/leaflet.css";
import noop from "lodash/noop";

type MapCache = { lat?: number; lng?: number; zoom?: number };
type VehicleClickHandler = (v: VisualMapVehicle | null) => void;

export default class MapBuilder {
  mapHost: HTMLDivElement;
  _l: typeof leaflet;
  _minZoom: number;
  _maxZoom: number;
  _zoomTo: number;
  _mapCache: MapCache;
  _saveMapCacheField: (fields: MapCache) => void;
  _latOffset: number;
  _map: L.Map;
  _restrictedAreasGroup: L.LayerGroup;
  _mcg: L.MarkerClusterGroup;
  _lastLocation: L.LatLng | undefined;
  _locationMarker: L.AnimatedMarker | undefined;
  _locationAccuracyCircle: L.Circle | undefined;
  _animationTimeoutId: number | null | undefined;
  _refreshId: number | null | undefined;
  _clickedVehicle: L.Marker | null | undefined;
  _onVehicleClick: VehicleClickHandler;
  _onSelectedVehicleRemoved: () => void;
  _lastExtendedVehicleBounds: L.LatLngBounds;
  _lastExtendedStaticBounds: L.LatLngBounds;

  constructor(host: HTMLDivElement) {
    this.mapHost = host;
    this._l = leaflet;
    this._minZoom = 8;
    this._maxZoom = 23;
    this._zoomTo = 20;
    this._onVehicleClick = noop;
    this._onSelectedVehicleRemoved = noop;
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
    this._lastExtendedStaticBounds = this._map.getBounds();
    this._lastExtendedVehicleBounds = this._map.getBounds();
    this._l.control
      .zoom({
        position: "bottomright",
        zoomInTitle: r("mobility.zoom_in"),
        zoomOutTitle: r("mobility.zoom_out"),
      })
      .addTo(this._map);
    this.updateLastExtendedVehicleBounds();
    this.updateLastExtendedStaticBounds();
    this._restrictedAreasGroup = this._l.layerGroup();
    this._mcg = this._l.markerClusterGroup({
      spiderfyOnMaxZoom: false,
      showCoverageOnHover: false,
      chunkedLoading: true,
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
    this.getAndUpdateRestrictedAreas(
      this._lastExtendedStaticBounds,
      this._restrictedAreasGroup
    );
    this._map.addLayer(this._restrictedAreasGroup);
    return this;
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
      this._locationAccuracyCircle
        .getElement()
        ?.classList.remove("mobility-location-accuracy-circle-transition");
      this.setLocationMarkerTransition("none");
    });
    this._map.on("zoomend", () => {
      if (!this._locationAccuracyCircle || !this._locationMarker) {
        return;
      }
      this._animationTimeoutId = window.setTimeout(() => {
        this._locationAccuracyCircle
          ?.getElement()
          ?.classList.add("mobility-location-accuracy-circle-transition");
        this.setLocationMarkerTransition("all 1000ms linear 0s");
      }, 250);
    });
  }

  setLocationMarkerTransition(value: string) {
    const el = this._locationMarker?.getElement();
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
    let vehicleOOB = false;
    let staticOOB = false;
    if (!this._lastExtendedStaticBounds.contains(bounds)) {
      vehicleOOB = true;
      staticOOB = true;
    } else if (!this._lastExtendedVehicleBounds?.contains(bounds)) {
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
  setVehicleEventHandlers({
    onClick,
    onSelectedRemoved,
  }: {
    onClick: VehicleClickHandler;
    onSelectedRemoved: () => void;
  }) {
    this._onVehicleClick = onClick;
    this._onSelectedVehicleRemoved = onSelectedRemoved;
    return this;
  }

  loadScooters() {
    this.getAndUpdateScooters(this._lastExtendedVehicleBounds, this._mcg);
    this.setMapEventHandlers();
    this._map.addLayer(this._mcg);
  }

  getAndUpdateScooters(bounds: L.LatLngBounds, mcg: L.MarkerClusterGroup) {
    api.getMobilityMap(boundsToParams(bounds)).then((r) => {
      this.updateScooters({ data: r.data, bounds, mcg });
      this._refreshId = refreshTimer(
        () => this.getAndUpdateScooters(bounds, mcg),
        r.data.refresh
      );
    });
  }

  updateScooters({
    data,
    bounds,
    mcg,
  }: {
    data: MobilityMap;
    bounds: L.LatLngBounds;
    mcg: L.MarkerClusterGroup;
  }) {
    const precisionFactor = 1 / data.precision;
    const applicableMarkers: leaflet.Layer[] = [];
    const allNewMarkersIds: string[] = [];
    const leftoverMarkers: leaflet.Marker[] = [];
    // First: Removes markers that are not present in the bounds
    const removableMarkers = mcg
      .getLayers()
      .filter(isMarker)
      .filter((marker) => !bounds.contains(marker.getLatLng()));
    mcg.removeLayers(removableMarkers);
    // Second: Add markers for ids that are missing
    const currentMarkersIds = mcg
      .getLayers()
      .filter(isMarker)
      .map((marker) => marker.options.id);
    const vehicleTypeAndVehicles = [
      { vehicleType: "ebike", vehicles: data.ebike || [] },
      { vehicleType: "escooter", vehicles: data.escooter || [] },
    ];
    vehicleTypeAndVehicles.forEach(({ vehicleType, vehicles }) => {
      vehicles.forEach((bike: MobilityMapVehicle) => {
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
        } else {
          leftoverMarkers.push(marker);
        }
        allNewMarkersIds.push(id);
      });
    });
    mcg.addLayers(applicableMarkers);
    // Third: Remove *leftover* markers that are not present in the new list of ids
    // Leftover markers are visible in new bounds but might not exist in new list of ids,
    // therefor we should remove the non-existing leftover marker(s)
    const removableLeftoverMarkers = leftoverMarkers.filter(
      (marker) => !allNewMarkersIds.includes(marker.options.id!)
    );
    mcg.removeLayers(removableLeftoverMarkers);

    // Fourth: Close the map reserve card if the marker for a scooter is now gone
    const removedMarkers = removableMarkers.concat(removableLeftoverMarkers);
    const isVehicleRemoved = removedMarkers
      .filter(isMarker)
      .find((marker) => this._clickedVehicle?.options.id === marker.options.id);
    if (!this._clickedVehicle || !isVehicleRemoved) {
      // Keep the card open if we didn't have one open, or the vehicle hasn't been removed.
      return;
    }
    this._onSelectedVehicleRemoved();
    this._clickedVehicle = null;
  }

  createVehicleMarker(
    id: string,
    bike: MobilityMapVehicle,
    vehicleType: string,
    vehicleProvider: MobilityMapProvider,
    precisionFactor: number
  ) {
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
        this._onVehicleClick!(mapVehicle);
        this._clickedVehicle = e.target;
      });
  }

  getAndUpdateRestrictedAreas(bounds: L.LatLngBounds, group: L.LayerGroup) {
    api
      .getMobilityMapFeatures(boundsToParams(bounds))
      .then(api.pickData)
      .then((d: MobilityMapFeatures) => {
        this.updateRestrictedAreas(d.restrictions, group);
      });
  }

  updateRestrictedAreas(restrictions: MobilityMapRestriction[], group: L.LayerGroup) {
    const currentRestrictionsIds = group
      .getLayers()
      .map((layer: L.Layer) => layer.options.id);
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

  createRestrictedArea({
    id,
    latlngs,
    restriction,
  }: {
    id: string;
    latlngs: GeoMultiPolygon;
    restriction: string;
  }) {
    if (!id || !latlngs || !restriction) {
      return;
    }
    const popup = this._l.popup({
      // direction: "top",
      offset: [0, 10],
    });
    const parkingRestrictionContent = `<h3>${t("mobility.do_not_park_title")}</h3><p>${t(
      "mobility.do_not_park_intro"
    )}</p>`;
    const ridingRestrictionContent = `<h3>${t("mobility.do_not_ride_title")}</h3><p>${t(
      "mobility.do_not_ride_intro"
    )}</p>`;

    if (restriction.startsWith("do-not-park-or-ride")) {
      popup.setContent(parkingRestrictionContent + "<hr />" + ridingRestrictionContent);
    } else if (restriction.startsWith("do-not-park")) {
      popup.setContent(parkingRestrictionContent);
    } else if (restriction.startsWith("do-not-ride")) {
      popup.setContent(ridingRestrictionContent);
    }
    return this._l
      .polygon(latlngs, {
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
    // noinspection JSUnusedGlobalSymbols
    const LocateControl = this._l.Control.extend({
      options: {
        position: "bottomright",
        link: undefined,
        center: (e: Event) => {
          e.preventDefault();
          if (!this._lastLocation) {
            return;
          }
          this.centerLocation(this._lastLocation, this._getLocationZoom());
        },
      } as LocateControlOptions,
      onAdd() {
        const container = L.DomUtil.create(
          "div",
          "leaflet-control-locate leaflet-bar leaflet-control"
        );
        const link = L.DomUtil.create(
          "a",
          "leaflet-bar-part leaflet-bar-part-single",
          container
        );
        link.href = "#";
        link.title = r("mobility.locate_me");
        link.setAttribute("role", "button");
        link.setAttribute("aria-label", r("mobility.locate_me"));
        link.innerHTML = locationSvg;
        this.options.link = link;
        L.DomEvent.on(this.options.link, "click", (e) => this.options.center(e), this);
        L.DomEvent.on(this.options.link, "dblclick", (ev) => {
          L.DomEvent.stopPropagation(ev);
        });
        return container;
      },
      onRemove() {
        L.DomEvent.off(this.options.link!, "click", (e) => this.options.center(e), this);
        L.DomEvent.off(this.options.link!, "dblclick", (ev) => {
          L.DomEvent.stopPropagation(ev);
        });
      },
    });
    return new LocateControl();
  }

  /**
   * @param onLocationFound Called with the leaflet LocationEvent
   * @param onLocationError Called with (this, {error, cachedLocation: {lat, lng} | null})
   */
  startTrackingLocation({
    onLocationFound,
    onLocationError,
  }: {
    onLocationFound: (location: any) => void;
    onLocationError: (
      self: MapBuilder,
      info: { error: any; cachedLocation: any }
    ) => void;
  }): MapBuilder {
    // 'watch' is true, so "locationfound" event is called multiple times.
    // We set lastLoc and create the movement line on the first location found;
    // then we update lastLoc, and append to the movement line, on subsequent location finds.
    let lastLoc: L.LatLng, movementLine: L.Polyline;
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
            this.centerLocation(lastLoc, this._getLocationZoom());
          }
          onLocationFound(location);
        }
        const { lat, lng } = location.latlng;
        if (
          this._locationMarker &&
          this._locationAccuracyCircle &&
          lastLoc &&
          movementLine &&
          (lastLoc.lat !== lat || lastLoc.lng !== lng)
        ) {
          this._locationMarker.stop();
          const nextLocation = { lat, lng };
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

  centerLocation(latlng: L.LatLng, targetZoom: number = 0) {
    const { lat, lng } = latlng;
    targetZoom = targetZoom || 18;
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
    const biased = this._l.latLngBounds(
      { lat: b.getSouth() - staticDegreesPad, lng: b.getWest() - staticDegreesPad },
      { lat: b.getNorth() + staticDegreesPad, lng: b.getEast() + staticDegreesPad }
    );
    this._lastExtendedStaticBounds = biased;
  }
}

function boundsToParams(bounds: L.LatLngBounds) {
  return {
    sw: [bounds.getSouth(), bounds.getWest()],
    ne: [bounds.getNorth(), bounds.getEast()],
  };
}

const refreshTimer = (function () {
  let timer: number = 0;
  // Because the inner function is bound to the refreshTimer variable,
  // it will remain in scope and will allow the timer variable to be manipulated
  return function (cb: TimerHandler, ms: number) {
    window.clearTimeout(timer);
    timer = window.setInterval(cb, ms);
    return timer;
  };
})();

const isMarker = (layer: L.Layer): layer is L.Marker => layer instanceof L.Marker;

export interface VisualMapVehicle {
  loc: number[];
  type: string;
  disambiguator: string;
  provider: MobilityMapProvider;
}

const locationSvg = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
  <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 3.75H6A2.25 2.25 0 0 0 3.75 6v1.5M16.5 3.75H18A2.25 2.25 0 0 1 20.25 6v1.5m0 9V18A2.25 2.25 0 0 1 18 20.25h-1.5m-9 0H6A2.25 2.25 0 0 1 3.75 18v-1.5M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
</svg>
`;

interface LocateControlOptions extends L.ControlOptions {
  link: undefined | HTMLAnchorElement;
  center: (e: Event) => void;
}
