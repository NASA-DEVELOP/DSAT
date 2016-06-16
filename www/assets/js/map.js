// create a map in the "map" div, set the view to a given place and zoom
var map = L.map('Map').setView([37.58, -122.31], 10);

// add an OpenStreetMap tile layer
L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}', {
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
    maxZoom: 18,
    id: 'developnn.b91b5b31',
    accessToken: 'pk.eyJ1IjoiZGV2ZWxvcG5uIiwiYSI6IjcwZGI2N2JhNmMwMGY3ZjA0ZjU0MzNhNzdlODM5MTY5In0.Dt00S_MWiFDZm9_y_xAwRg'
}).addTo(map);

// weird thing, must resize for loading. 
// Bootstrap + leaflet quirk. See here: 
// https://www.mapbox.com/help/why-map-cropped-hidden-shown/
$('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
  var target = $(e.target).attr("href") // activated tab
  // alert(target);
  map.invalidateSize();
});



