# Tiled Vegetation Indices

Ruby on Rails web-application that leverages **[libvips](https://libvips.github.io/libvips/)** image processing library and **[Leaflet](https://leafletjs.com)** interactive maps library to apply [Vegetation Indices](https://en.wikipedia.org/wiki/Vegetation_Index) (VIs) on [map tiles](https://en.wikipedia.org/wiki/Tiled_web_map).

The approach was taken after analyzing how **[DroneDeploy](https://www.dronedeploy.com/)** works with VIs.

It is being published as open source to demonstrate how [WebODM](https://github.com/OpenDroneMap/WebODM) contributors can apply VIs on-the-fly on map tiles. This approach avoids the need to store different tiles for each VI.

## Approach

It is generated a **thumbnail** of the full orthophoto. Then it is applied each one of the implemented indices on the thumbnail and is saved a **histogram** of each **index result**.

The histogram is then used to calculate a `min` and `max` used to "clip" results bellow/above min/max on individual tiles.

## Implemented Indices

### RGB based:
* VARI
* GLI
* IOR
* NGRI

### NIR based:
* NDVI
* BAI
* SAVI
* MNLI
* MSR
* RDVI
* TDVI
* OSAVI
* LAI

## Screen Capture

### RGB based VARI

![alt text](https://raw.githubusercontent.com/dirceup/tiled-vegetation-indices/master/public/VARI.png)

### NIR based NDVI

![alt text](https://raw.githubusercontent.com/dirceup/tiled-vegetation-indices/master/public/NDVI.png)

## Where to look

[app/lib/vegetation_index.rb](https://github.com/dirceup/tiled-vegetation-indices/blob/master/app/lib/vegetation_index.rb)

[app/controllers/vegetation_index_controller.rb](https://github.com/dirceup/tiled-vegetation-indices/blob/master/app/controllers/vegetation_index_controller.rb)

[app/assets/javascripts/map.js](https://github.com/dirceup/tiled-vegetation-indices/blob/master/app/assets/javascripts/map.js)

## Wait, what?

Please follow through this file: [app/lib/vegetation_index.rb](https://github.com/dirceup/tiled-vegetation-indices/blob/master/app/lib/vegetation_index.rb)

→

The method `generate_orthophoto_statistics` does generate a reduced dimension version of the full orthophoto because it is more efficient computationally to proceed with it reduced.
It then calls `run_and_store_indices_statistics` that will call `index_statistics` for each Vegetation Index that we want to use.

`index_statistics` does apply a specified Vegetation Index to the reduced orthophoto and returns it's "min" and "max" values along with their "histogram with 256 bins".

Now you can call `apply_index` for each tile generated from the full dimension orthophoto sending the "min"/"max" calculated by `index_statistics`. Or even better, you can use [findClippedMinMax()](https://github.com/dirceup/tiled-vegetation-indices/blob/master/app/assets/javascripts/map.js#L166) JavaScript method to increase the contrast by ignoring "the first and last 3% histogram values" and calculating a better "min"/"max" (clipped_min/clipped_max) to use in `apply_index`.

## JavaScript Libraries Used

#### [Leaflet](https://leafletjs.com/)

#### [Leaflet.AutoLayers](https://github.com/aebadirad/Leaflet.AutoLayers)

#### [Chartist](https://gionkunz.github.io/chartist-js/)

#### [jQuery 3.4.0](https://jquery.com/)

#### [Multirange](https://leaverou.github.io/multirange/)

#### [d3-color](https://d3js.org/d3-color/)

#### [d3-interpolate](https://d3js.org/d3-interpolate/)

#### [d3-scale-chromatic](https://d3js.org/d3-scale-chromatic/)

## Requeriments

#### [libvips](https://github.com/libvips/ruby-vips)

#### [Ruby](https://www.ruby-lang.org/en/)

#### [Ruby on Rails](https://rubyonrails.org/)
