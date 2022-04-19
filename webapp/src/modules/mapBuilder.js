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
  }

  init() {
    this._map = this._l
      .map(this.mapRef.current)
      .setView([this._dLat, this._dLng], this._dZoom);
    this.setTileLayer();
    this.setScooterIcon();
    this.setMarkerCluster();
    this.getScooters();
    // add markers to markerCluster after setting mcg layers in getScooters
    // no need to add mcg everytime we getScooters, we simply addLayer to mcg
    this._map.addLayer(this._mcg, {
      chunkedLoading: true,
      chunkInterval: 350,
    });

    this._map.on("moveend", () => {
      this.getScooters();
    });

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
          maxZoom: 23,
          minZoom: 12,
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
    const bounds = this._map.getBounds();
    const removableLayers = [];
    this._mcg.eachLayer((marker) => {
      if (bounds.contains(marker._latlng)) {
        removableLayers.push(marker);
      }
    });
    // removeLayers preferred over removeLayer for efficient performance
    this._mcg.removeLayers(removableLayers);
  }

  getScooters() {
    const { _northEast, _southWest } = this._map.getBounds();
    api
      .getMobilityMap({
        minloc: [_southWest.lat, _southWest.lng],
        maxloc: [_northEast.lat, _northEast.lng],
      })
      .then((r) => {
        const precisionFactor = 1 / r.data.precision;
        const newMarkers = [];
        this.removeVisibleLayers();
        r.data.escooter?.forEach((bike) => {
          const [lat, lng] = bike.c;
          const marker = this.newMarker([lat * precisionFactor, lng * precisionFactor]);
          newMarkers.push(marker);
        });
        // addLayers preferred over addLayer for efficient performance
        this._mcg.addLayers(newMarkers);
      });
  }

  newMarker(latLng) {
    return this._l
      .marker([latLng[0], latLng[1]], {
        icon: this._scooterIcon,
      })
      .on("click", (e) => {
        const { lat, lng } = e.latlng;
        const lowerTo = 0.00004;
        const loweredLat = lat + lowerTo;
        this._map.flyTo([loweredLat, lng], 21, {
          animate: true,
          duration: 1.5,
        });
      });
  }
}
