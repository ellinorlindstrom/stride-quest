<script lang="ts">

	import { onMount } from "svelte";
    import { fetchLocations } from "$lib/services/supabase";

    let locations = []
    let map: google.maps.Map

    const api = import.meta.env.VITE_GOOGLE_MAPS_API_KEY

    function loadMap() {
    const script = document.createElement('script')
    script.src = `https://maps.googleapis.com/maps/api/js?key=${api}&callback=initMap`
    script.async = true
    script.defer = true
    document.head.appendChild(script)
}

function initMap() {
    const mapOptions: google.maps.MapOptions = {
        center: { lat: 40.7128, lng: -74.0060 },
        zoom: 12
    }
    map = new google.maps.Map(document.getElementById('map') as HTMLElement, mapOptions)
}

onMount(async() => {
    loadMap()
    window.initMap = initMap;
    locations = await fetchLocations()
    console.log(locations)
})

 </script>

<svelte:head>
    <script src="https://maps.googleapis.com/maps/api/js?key={api}" type="text/javascript"></script>
  </svelte:head>



 <style>
    #map {
        height: 100vh;
        width: 100%;
    }
 </style>

    <div id="map"></div>