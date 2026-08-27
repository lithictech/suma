import * as L from "leaflet";

declare module "leaflet" {
  interface AnimatedMarkerOptions extends L.MarkerOptions {
    autoStart?: boolean;
    icon?: L.Icon | L.DivIcon;
    onEnd?: () => void;
    interactive?: boolean;
    duration?: number;
    distance?: number; // suma extension, I think?
  }

  interface AnimatedMarker extends L.Marker {
    options: AnimatedMarkerOptions;
    start(): void;
    stop(): void;
  }

  function animatedMarker(
    latlngs: L.LatLngExpression[] | L.LatLngExpression[][] | L.LatLngExpression[][][],
    options?: AnimatedMarkerOptions
  ): AnimatedMarker;
}
