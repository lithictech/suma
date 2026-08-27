import * as L from "leaflet";

declare module "leaflet" {
  interface LayerOptions {
    id?: string;
  }
}
