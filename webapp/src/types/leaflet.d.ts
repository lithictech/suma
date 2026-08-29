// noinspection ES6UnusedImports
import "leaflet";

declare module "leaflet" {
  interface LayerOptions {
    id?: string;
  }
}
