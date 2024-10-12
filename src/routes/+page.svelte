<script lang="ts">

	import { onDestroy, onMount } from "svelte";
    import { addLocationToDB, fetchLocations } from "$lib/services/supabase";

    let locations: { lat: number, lng: number }[] = []
    let map: google.maps.Map
    let mapLoaded = false
    let watchId: number
    let path: google.maps.Polyline
    let currentPositionMarker: google.maps.Marker

    const api = import.meta.env.VITE_GOOGLE_MAPS_API_KEY



    function loadMap() {
    const script = document.createElement('script')
    script.src = `https://maps.googleapis.com/maps/api/js?key=${api}&libraries=places&callback=initMap`
    script.async = true
    script.defer = true
    document.head.appendChild(script)
}

function initMap() {
    console.log("initMap anropas 🗺️")
    const mapOptions: google.maps.MapOptions = {
        center: { lat: 40.7128, lng: -74.0060 },
        zoom: 17,
    }
    map = new google.maps.Map(document.getElementById('map') as HTMLElement, mapOptions)
    mapLoaded = true
    setUpSearch()
    addMarkers()
    startTracking()
}

function setUpSearch() {
    const input = document.getElementById('pac-input') as HTMLInputElement
    const autoComplete = new google.maps.places.Autocomplete(input)
    autoComplete.bindTo('bounds', map);

    autoComplete.addListener('place_changed', () => {
        const place = autoComplete.getPlace()
        if (!place.geometry) return

        if (place.geometry.viewport) {
            map.fitBounds(place.geometry.viewport)
        } else {
            map.setCenter(place.geometry.location)
            map.setZoom(15)
        }
    })
   
}

    function addMarkers() {
        if (!mapLoaded) return
    locations.forEach(location => {
        console.log("adding marker: ", location)
        const marker = new google.maps.Marker({
            position: location,
            map: map
        })
    })
    };

    function startTracking() {
        if (!mapLoaded || !navigator.geolocation) return
        path = new google.maps.Polyline({
            path: [],
            geodesic: true,
            strokeColor: '#FF0000',
            strokeOpacity: 1.0,
            strokeWeight: 2,
            map: map
        })
        
        watchId = navigator.geolocation.watchPosition(
            (position) => {
                const lat = position.coords.latitude;
                const lng = position.coords.longitude;
                const newPosition = new google.maps.LatLng(lat, lng)

                const currentPath = path.getPath()
                currentPath.push(newPosition)
                path.setPath(currentPath)

                if (currentPositionMarker) {
                    currentPositionMarker.setPosition(newPosition)
                } else {
                    currentPositionMarker = new google.maps.Marker({
                        position: newPosition,
                        map: map,
                        icon: {
                            path: google.maps.SymbolPath.CIRCLE,
                            scale: 7,
                            fillColor: '#4285F4',
                            fillOpacity: 1,
                            strokeWeight: 2,
                            strokeColor: '#FFFFFF'
                        }
                    })
                }

                map.setCenter(newPosition)
            },
            (error) => {
                  console.error('Error in geolocation watch:', error)
            },
        {
            enableHighAccuracy: true,
            timeout: 5000,
            maximumAge: 0
        }
        )
    }


onMount(async() => {
    window.initMap = initMap;
    loadMap()
    await addLocationToDB()
    locations = await fetchLocations()
    console.log(locations)
    if (mapLoaded) addMarkers()
})

onDestroy(() => {
    if (watchId)navigator.geolocation.clearWatch(watchId);
})

 </script>

 <input id="pac-input" class="controls" type="text" placeholder="Search">

 <div id="map"></div>

 <style>
    #map {
        height: 100vh;
        width: 100%;
    }
    .controls {
      margin-top: 10px;
      background-color: #fff;
      padding: 10px 20px;
      border: none;
      max-width: 240px;
      font-family: Roboto;
      font-size: 15px;
      font-weight: 300;
      position: absolute;
      z-index: 1000;
      left: 50%;
      transform: translateX(-50%);
    }
 </style>
