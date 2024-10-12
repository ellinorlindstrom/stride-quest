declare namespace google.maps {
    class Map {
      constructor(mapDiv: Element | null, opts?: MapOptions);
      fitBounds(bounds: LatLngBounds | LatLngBoundsLiteral): void;
        setCenter(latLng: LatLng | LatLngLiteral): void;
        setZoom(zoom: number): void;
    }
    const SymbolPath: {
        BACKWARD_CLOSED_ARROW: number;
        BACKWARD_OPEN_ARROW: number;
        CIRCLE: number;
        FORWARD_CLOSED_ARROW: number;
        FORWARD_OPEN_ARROW: number;
    };

    class LatLng {
      constructor(lat: number, lng: number);
    }

    class Polyline {
        constructor(opts?: PolylineOptions);
        setMap(map: Map | null): void;
        getPath(): MVCArray<LatLng>;
        setPath(path: LatLng[] | MVCArray<LatLng>): void;
    }

    class Marker {
        constructor(opts?: MarkerOptions);
        setMap(map: Map | null): void;
        setPosition(latLng: LatLng | LatLngLiteral): void;
    }
    

    interface PolylineOptions {
        path?: LatLng[] | MVCArray<LatLng>;
        strokeColor?: string;
        strokeOpacity?: number;
        strokeWeight?: number;
        clickable?: boolean;
        draggable?: boolean;
        editable?: boolean;
        geodesic?: boolean;
        icons?: IconSequence[];
        map?: Map;
        visible?: boolean;
        zIndex?: number;
    }

    interface IconSequence {
        fixedRotation?: boolean;
        icon?: symbol;
        offset?: string;
        repeat?: string;
    }

    class Marker {
      constructor(opts?: MarkerOptions);
      setMap(map: Map | null): void;
    }
  
    interface MapOptions {
      center?: LatLngLiteral;
      zoom?: number;
    }
namespace places {
  class Autocomplete {
    constructor(input: HTMLInputElement, opts?: AutocompleteOptions);
    getPlace(): PlaceResult;
    bindTo(key: string, target: MVCObject, targetKey?: string, noNotify?: boolean): void;
    setBounds(bounds: LatLngBounds | LatLngBoundsLiteral): void;
    addListener(eventName: string, handler: (...args: unknown[]) => void): MapsEventListener;
 
  }

  interface AutocompleteOptions {
    bounds?: LatLngBounds | LatLngBoundsLiteral;
    componentRestrictions?: ComponentRestrictions;
    fields?: string[];
    placeIdOnly?: boolean;
    strictBounds?: boolean;
    types?: string[];
  }

  interface PlaceResult {
    address_components?: AddressComponent[];
    adr_address?: string;
    formatted_address?: string;
    geometry?: PlaceGeometry;
    icon?: string;
    id?: string;
    name?: string;
    place_id?: string;
    reference?: string;
    types?: string[];
    url?: string;
    utc_offset?: number;
    vicinity?: string;
    html_attributions?: string[];
  }

  interface AddressComponent {
    long_name: string;
    short_name: string;
    types: string[];
  }

  interface PlaceGeometry {
    location: LatLng;
    viewport: LatLngBounds;
  }

  interface ComponentRestrictions {
    country: string | string[];
  }
}
    interface LatLngLiteral {
      lat: number;
      lng: number;
    }
  }
  
  interface Window {
    initMap: () => void;
  }