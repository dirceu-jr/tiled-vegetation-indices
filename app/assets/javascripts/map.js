var
  map = L.map('map', {
    attributionControl: false
  }),
  info = {},
  tile_layer,
  index_histogram_chart,
  statistics,
  clip = false,
  clipped_min,
  clipped_max
;


function addTileLayer(info) {

  // updates global (to be used by VIs)
  window.info = info;

  // clear previous
  if (tile_layer) {
    map.removeLayer(tile_layer);
  }

  // get processing bounds
  var bounds = L.latLngBounds(
    [info.bounds.slice(0, 2).reverse(), info.bounds.slice(2, 4).reverse()]
  );
  // set map view to processing bounds
  map.fitBounds(bounds);

  // add a layer with orthophoto tiles
  tile_layer = L.tileLayer(info.tiles.join(""), {
    bounds: bounds,
    minZoom: info.minzoom,
    maxZoom: L.Browser.retina ? (info.maxzoom + 1) : info.maxzoom,
    maxNativeZoom: L.Browser.retina ? (info.maxzoom - 1) : info.maxzoom,
    tms: info.scheme === "tms",
    opacity: 1,
    detectRetina: true
  });

  tile_layer.addTo(map);

}


function indices_of_base(base) {

  // clear histogram
  $("#index_histogram").html("");

  // updates tile
  get_tiles_info(base);

  if (base == "rgb") {
    var selects = ["vari", "gli", "ior", "ngri"];
  } else if (base == "nir") {
    var selects = ["ndvi", "savi", "mnli", "osavi", "bai", "msr", "rdvi", "tdvi", "lai"];
  }

  var html = ["<option value='none'>None</option>"];

  for (select in selects) {
    html.push(
      "<option value='", selects[select], "'>", selects[select].toUpperCase(), "</option>"
    );
  }

  $("#vi").html(html.join(""));
}


function get_tiles_info(base) {
  $.ajax("/" + base + "_orthophoto/tiles.json").done(function(info) {
    addTileLayer(info);
  });
}


// render index histogram data as a graph
function renderIndexHistogram() {

  var
    holder = $("#index_histogram"),
    histogram_data = statistics.histogram_256
  ;

  if (index_histogram_chart) {
    index_histogram_chart.detach();
  }

  // ! - Sometimes there is a outlier
  for (var el in histogram_data) {
      if (histogram_data[el] > 10000) {
          histogram_data[el] = 1000;
      }
  }

  var
      data = {
          labels: [statistics.min.toFixed(2), statistics.max.toFixed(2)],
          series: [
              histogram_data
          ]
      },
      options = {
          width: 279,
          height: 160,
          axisX: {
              offset: 15
          },
          axisY: {
              showLabel: false,
              offset: -2
          }
      },
      // used to colorize chart bars
      // color_counter = 0,
      // used in chart for each bar draw
      draw_counter = 0,
      color_map = generateColorMap("RdYlGn", 256)
  ;

  // use Chartist library to draw a chart
  index_histogram_chart = new Chartist.Bar(holder[0], data, options);

  // on draw of every element of chart
  index_histogram_chart.on("draw", function(context) {
      // only if element is "bar"
      if (context.type == "bar") {
          var color = color_map[draw_counter];
          draw_counter++;

          // apply a different color in each bar using pre-defined "color_map"
          context.element.attr({
              style: "stroke-width: 1px; stroke: " + color
          });
          
          if (draw_counter >= histogram_data.length) {
              draw_counter = 0;
          }
      }
  });

  // on chart "draw end"
  index_histogram_chart.on("created", function() {
      // adjust labels position
      min_label = $(".ct-labels > foreignObject:eq(0)");
      max_label = $(".ct-labels > foreignObject:eq(1)");

      if (min_label[0]) {
          min_label[0].setAttribute("x", "0");
      }

      if (max_label[0]) {
          max_label[0].setAttribute("x", "254");
      }

      renderRangeInput(holder);
      reColorizeIndexHistogram();
  });
}


function findClippedMinMax() {
  var
      data = statistics.histogram_256,
      // used to find clipped_min and clipped_max with data
      sum = data.reduce(add, 0),
      clip_3_percent = sum * .03,
      lower_sum = 0,
      upper_sum = 0,
      last_lower_i,
      last_upper_i
  ;

  // iterate over data
  for (var i = 0; i < data.length; i++) {
      // summing up values in lower_sum til the sum is >= 3% of the sum of all data values
      // last_lower_i will be the data position right before lower_sum summed equal to 3% of the sum of all data values
      if (lower_sum < clip_3_percent) {
          lower_sum += data[i];
          last_lower_i = i;
      }

      // the same with last_upper_i
      if (upper_sum < clip_3_percent) {
          upper_sum += data[data.length-1-i];
          last_upper_i = data.length-1-i;
      }
  }

  // remap last_lower_i and last_upper_i "position" into min/max range of "Statistics"
  clipped_min = math_map_value(last_lower_i, 0, 255, statistics.min, statistics.max);
  clipped_max = math_map_value(last_upper_i, 0, 255, statistics.min, statistics.max);
}


// used to sum array values with Array.reduce(fn, 0)
function add(a, b) {
  return a + b;
}


// Remaps value (that has an expected range of in_low to in_high) into a target range of to_low to to_high
function math_map_value(value, in_low, in_high, to_low, to_high) {
  return to_low + (value - in_low) * (to_high - to_low) / (in_high - in_low);
}


// Generate a colormap using d3-scale-chromatic
function generateColorMap(colormap, nshades) {
  var
      step = 1/(nshades-1),
      result = []
  ;
  for (var i = 0; i <= (nshades-1); i++) {
      var color = d3.interpolateRdYlGn(i * step);
      result.push(color);
  }
  
  return result;
}


// clear previous added and add multirange slider
function renderRangeInput(holder) {
  
  // clear previous added
  var range_holder = $("#range_selector");
  if (range_holder[0]) {
      range_holder.remove();
  }

  // verify if clip option is enabled
  if (clip) {
      // use clipped calculated values
      var value = clipped_min + "," + clipped_max;

      updateMinMaxLabels(clipped_min, clipped_max);
  } else {
      var value = statistics.min + "," + statistics.max;
  }

  // add input with type=range
  var range = $("<div id='range_selector'><input type='range' multiple min='" + statistics.min + "' max='" + statistics.max + "' value='" + value + "' step='0.0001' style='width: 271px' /></div>");
  holder.append(range);

  // initialize "multirange" library
  multirange.init();

  // when user end dragging the range selector
  $("#range_selector input").on("change", function() {

      // set clip mode on when change range
      clip = true;

      // set min/max used by Tile rendering and re-load Tiles
      clipped_min = this.valueLow;
      clipped_max = this.valueHigh;
      changeTileLayer();

      // re-render Index Histogram chart to it use clipped_min & clipped_max
      reColorizeIndexHistogram();
      
  });

  // when value of range selector changes
  $("#range_selector input").on("input", function() {
      updateMinMaxLabels(this.valueLow, this.valueHigh);
  });
}


// update Index histogram chart labels
function updateMinMaxLabels(valueLow, valueHigh) {
  if (min_label && min_label[0]) {
      // update labels values
      min_label[0].childNodes[0].innerText = valueLow.toFixed(2);
      max_label[0].childNodes[0].innerText = valueHigh.toFixed(2);
      // update labels positions mapping values to meet min/max positions in pixels
      min_label[0].setAttribute("x", math_map_value(valueLow, statistics.min, statistics.max, 0, 254));
      max_label[0].setAttribute("x", math_map_value(valueHigh, statistics.min, statistics.max, 0, 254));
  }
}


// when user select a custom range of min/max we re-colorize Histogram Graph considering select range
function reColorizeIndexHistogram() {
  if (clip) {    
      var
          counter_min = Math.floor(math_map_value(clipped_min, statistics.min, statistics.max, 0, 255)),
          counter_max = Math.floor(math_map_value(clipped_max, statistics.min, statistics.max, 0, 255)),
          colors_needed = (counter_max - counter_min) + 1,
          color_map = generateColorMap("RdYlGn", colors_needed),
          color_counter = 0
      ;

      var bars = $("#index_histogram svg .ct-series line");
      bars.each(function(i) {
          if (i <= counter_min) {
              var color = color_map[0];
          } else if (i >= counter_max) {
              var color = color_map[color_map.length-1];
          } else {
              var color = color_map[color_counter];
              color_counter++;
          }
          this.style = "stroke-width: 1px; stroke: " + color;
      });   
  }
}


function changeTileLayer() {
  var
      min = statistics.min,
      max = statistics.max
  ;

  if (clip) {
      min = clipped_min;
      max = clipped_max;
  }

  var
    base = $("#base").val(),
    val = $("#vi").val(),
    tile_url = ["/vegetation_index?index=", val, "&min=", min, "&max=", max, "&tile=", base, "_tiles/{z}/{x}/{y}.png"]
  ;

  // if (band_order != "") {
  //     tile_url.push("&band_order=", band_order);
  // }

  tile_layer.setUrl(tile_url.join(""));
}


// initialize base layers
var basemaps = {
  'Google Maps Hybrid': L.tileLayer('//{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}', {
      subdomains: ['mt0','mt1','mt2','mt3'],
      maxZoom: 21,
      minZoom: 0,
      label: 'Google Maps Hybrid'
      // detectRetina: true
  }).addTo(map),
  'Google Maps Terrain': L.tileLayer('//{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}', {
      subdomains: ['mt0','mt1','mt2','mt3'],
      maxZoom: 21,
      minZoom: 0,
      label: 'Google Maps Terrain'
  }),
  'No Map': L.tileLayer('/1px.gif', {
      maxZoom: 21,
      minZoom: 0,
      label: 'No Map'
  })
}

var autolayers = L.control.autolayers({
  overlays: {},
  selectedOverlays: [],
  baseLayers: basemaps
}).addTo(map);


$("#base").change(function() {
  var val = $(this).val();

  indices_of_base(val);
});


$("#vi").change(function() {
  var
    val = $(this).val()
    base = $("#base").val();
  ;

  if (val == "none") {

    indices_of_base(base);

  } else {

    $.ajax("/indices_statistics/" + val + ".json").done(function(statistics) {

      // updated global statistics
      window.statistics = statistics;

      // update global info
      info.tiles = ["/vegetation_index?index=", val, "&min=", statistics["min"], "&max=", statistics["max"], "&tile=", base, "_tiles/{z}/{x}/{y}.png"];
      addTileLayer(info);

      // is VI so renders histogram
      renderIndexHistogram();

      findClippedMinMax();
      clip = true;

      reColorizeIndexHistogram();
      changeTileLayer();

    });

  }

});


indices_of_base("rgb");