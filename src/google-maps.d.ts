declare namespace google.maps {
    class Map {
      constructor(mapDiv: Element | null, opts?: MapOptions);
    }
  
    interface MapOptions {
      center?: LatLngLiteral;
      zoom?: number;
    }
  
    interface LatLngLiteral {
      lat: number;
      lng: number;
    }
  }
  
  interface Window {
    initMap: () => void;
  }