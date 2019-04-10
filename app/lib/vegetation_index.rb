require 'histogram/array'
require 'colormaps'

class VegetationIndex

  include ColorMaps

  def self.index_statistics(index, filename, band_order=nil)
    index = index.gsub("-", "_")

    image = Vips::Image.new_from_file(filename)
    result = send(index, image, band_order)[1]

    flat_result = result.to_a.flatten

    # Some VIs thows errors in operations that does comparison between flat_results elements
    # That is because sometimes the VI results in a NaN Float
    # So before sorting or calculating min/max we need to remove NaN
    flat_result.reject! &:nan?

    freqs_256 = flat_result.histogram(256)[1]

    {
      min: result.min,
      max: result.max,
      histogram_256: freqs_256
    }
  end

  def self.bandsplit(image, band_order)
    if band_order == "GRN"
      second, first, third, a = image.bandsplit
    else
      first, second, third, a = image.bandsplit
    end
    [first, second, third, a]
  end

  def self.vari(image, band_order)
    r, g, b, a = bandsplit(image, band_order)
    index = (g - r) / (g + r - b)
    [a, index]
  end

  def self.ndvi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = (nir - r) / (nir + r)
    [a, index]
  end

  def self.bai(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = ((-r + 0.1) ** 2) + ((-nir + 0.06) ** 2) ** -1
    [a, index]
  end

  def self.gli(image, band_order)
    r, g, b, a = bandsplit(image, band_order)
    index = ((g * 2) - r - b) / ((g * 2) + r + b)
    [a, index]
  end

  # WIP - Need Image with Green Band
  def self.gndvi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = (nir - g) / (nir + g)
    [a, index]
  end

  # WIP - Need Image with Green Band
  def self.grvi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = nir - g
    [a, index]
  end

  def self.ior(image, band_order)
    r, g, b, a = bandsplit(image, band_order)
    index = r / b
    [a, index]
  end

  def self.savi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    l = 0.5
    index = ((nir - r) / (nir + r + l)) * (1 + l)
    [a, index]
  end

  def self.mnli(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    l = 0.5
    index = (((nir ** 2) - r) * (1 + l)) / ((nir ** 2) + r + l)
    [a, index]
  end

  def self.msr(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = ((nir / r) - 1) / (((nir / r) ** 0.5) + 1)
    [a, index]
  end

  def self.rdvi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = (nir - r) / ((nir + r) ** 0.5)
    [a, index]
  end

  def self.tdvi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    l = 0.5
    index = (((nir - r) / (nir + r)) + l) ** 0.5
    [a, index]
  end

  def self.osavi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    l = 1.5
    index = ((nir - r) / (nir + r + 0.16)) * l
    [a, index]
  end

  def self.ngri(image, band_order)
    r, g, b, a = bandsplit(image, band_order)
    index = (g - r) / (g + r)
    [a, index]
  end

  def self.lai(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    l = 0.5

    # We had this formula
    # (ln(0,69−SAVI)(0,59)/0,91
    # Where
    # savi = (((nir - r) / (nir + r + l)) * (1 + l))
    # index = ((-(((nir - r) / (nir + r + l)) * (1 + l)) + 0.69).log() * 0.59) / 0.91

    # But results was not as expected
    # I searched about and found:
    # https://www.sentinel-hub.com/eoproducts/lai-savi-leaf-area-index-soil-adjusted-vegetation-index
    # And
    # https://www.researchgate.net/file.PostFileLoader.html?id=5635f25060614b180d8b4567&assetKey=AS%3A290936253894656%401446376016229

    # Where there are a minus (-)Math.log()
    # And it worked as expected
    index = (-(-(((nir - r) / (nir + r + l)) * (1 + l)) + 0.69).log() / 0.59) / 0.91

    # This is sentinel-hub formula:
    # index = (-(-(((nir - r) / (nir + r + l)) * (1 + l)) + 0.371).log()) / 2.4

    [a, index]
  end

  def self.evi(image, band_order)
    r, b, nir, a = bandsplit(image, band_order)

    gc = 2.5
    l = 1
    c1 = 6
    c2 = 7.5

    index = ((nir - r) * gc) / nir + l + (r * c1) - (b * c2)

    [a, index]
  end

  def self.gndvi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = (nir - g) / (nir + g)
    [a, index]
  end

  def self.grvi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = nir / g
    [a, index]
  end

  def self.ndwi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = (g - nir) / (g + nir)
    [a, index]
  end

  def self.cvi(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = (nir - r) / g
    [a, index]
  end

  def self.ci_g(image, band_order)
    r, g, nir, a = bandsplit(image, band_order)
    index = (nir / g) - 1
    [a, index]
  end

  def self.apply_index(index, image, min=nil, max=nil, band_order=nil)

    index = index.gsub("-", "_")

    if image.class != Vips::Image
      image = Vips::Image.new_from_file(image)
    end

    a, result = send(index, image, band_order)

    min, max = prepare_minmax(result, min, max)

    # https://stats.stackexchange.com/questions/70801/how-to-normalize-data-to-0-1-range
    # This math is to "scale" a set (array) to values in 0->1 range
    # But... ~ Using min/max different then set min/max does "clip" results bellow or above min/max ~
    result = ((result-min) / (max-min).to_f) * 256

    rdylgn_image = Vips::Image.new_from_array(RdYlGn_lut).bandfold
    rgb = result.maplut(rdylgn_image)

    a.nil? ? rgb : rgb.bandjoin(a)
  end

  def self.prepare_minmax(result, min, max)
    unless min.nil?
      min = min.to_f
    else
      min = result.min
    end

    unless max.nil?
      max = max.to_f
    else
      max = result.max
    end

    [min, max]
  end

end