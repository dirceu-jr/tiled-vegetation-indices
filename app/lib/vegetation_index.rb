require 'histogram/array'
require 'colormaps'
require 'json'

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
      second, first, third, alpha = image.bandsplit
    else
      first, second, third, alpha = image.bandsplit
    end
    [first, second, third, alpha]
  end

  def self.vari(image, band_order)
    r, g, b, alpha = bandsplit(image, band_order)
    index = (g - r) / (g + r - b)
    [alpha, index]
  end

  def self.ndvi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = (nir - r) / (nir + r)
    [alpha, index]
  end

  def self.bai(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = ((-r + 0.1) ** 2) + ((-nir + 0.06) ** 2) ** -1
    [alpha, index]
  end

  def self.gli(image, band_order)
    r, g, b, alpha = bandsplit(image, band_order)
    index = ((g * 2) - r - b) / ((g * 2) + r + b)
    [alpha, index]
  end

  # OBS - Need Image with Green Band
  def self.gndvi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = (nir - g) / (nir + g)
    [alpha, index]
  end

  # OBS - Need Image with Green Band
  def self.grvi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = nir - g
    [alpha, index]
  end

  def self.ior(image, band_order)
    r, g, b, alpha = bandsplit(image, band_order)
    index = r / b
    [alpha, index]
  end

  def self.savi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    l = 0.5
    index = ((nir - r) / (nir + r + l)) * (1 + l)
    [alpha, index]
  end

  def self.mnli(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    l = 0.5
    index = (((nir ** 2) - r) * (1 + l)) / ((nir ** 2) + r + l)
    [alpha, index]
  end

  def self.msr(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = ((nir / r) - 1) / (((nir / r) ** 0.5) + 1)
    [alpha, index]
  end

  def self.rdvi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = (nir - r) / ((nir + r) ** 0.5)
    [alpha, index]
  end

  def self.tdvi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    l = 0.5
    index = (((nir - r) / (nir + r)) + l) ** 0.5
    [alpha, index]
  end

  def self.osavi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    l = 1.5
    index = ((nir - r) / (nir + r + 0.16)) * l
    [alpha, index]
  end

  def self.ngri(image, band_order)
    r, g, b, alpha = bandsplit(image, band_order)
    index = (g - r) / (g + r)
    [alpha, index]
  end

  def self.lai(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    l = 0.5

    index = (-(-(((nir - r) / (nir + r + l)) * (1 + l)) + 0.69).log() / 0.59) / 0.91

    [alpha, index]
  end

  def self.evi(image, band_order)
    r, b, nir, alpha = bandsplit(image, band_order)

    gc = 2.5
    l = 1
    c1 = 6
    c2 = 7.5

    index = ((nir - r) * gc) / nir + l + (r * c1) - (b * c2)

    [alpha, index]
  end

  def self.gndvi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = (nir - g) / (nir + g)
    [alpha, index]
  end

  def self.grvi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = nir / g
    [alpha, index]
  end

  def self.ndwi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = (g - nir) / (g + nir)
    [alpha, index]
  end

  def self.cvi(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = (nir - r) / g
    [alpha, index]
  end

  def self.ci_g(image, band_order)
    r, g, nir, alpha = bandsplit(image, band_order)
    index = (nir / g) - 1
    [alpha, index]
  end

  def self.apply_index(index, image, min=nil, max=nil, band_order=nil)

    index = index.gsub("-", "_")

    if image.class != Vips::Image
      image = Vips::Image.new_from_file(image)
    end

    alpha, result = send(index, image, band_order)

    min, max = prepare_minmax(result, min, max)

    # https://stats.stackexchange.com/questions/70801/how-to-normalize-data-to-0-1-range
    # This math is to "scale" a set (array) to values in 0->1 range
    # But... ~ Using min/max different then set min/max does "clip" results bellow or above min/max ~
    result = ((result-min) / (max-min).to_f) * 256

    rdylgn_image = Vips::Image.new_from_array(RdYlGn_lut).bandfold
    rgb = result.maplut(rdylgn_image)

    alpha.nil? ? rgb : rgb.bandjoin(alpha)
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

  # we are resizing with ruby-vips (libvips) because
  # it uses much less memory than RMagick (ImageMagick)
  def self.resize_image(filename, thumb_filename)
    # only resize if thumb does not exists
    unless File.file?(thumb_filename)
      image = Vips::Image.new_from_file(filename)
      # OBS: may it be better to scale a variable size?
      scale = 500.to_f/image.width
      resized = image.resize(scale, {kernel: :lanczos3})
      resized.write_to_file(thumb_filename)
    end
  end

  
  def self.run_and_store_indices_statistics(type_of, orthophoto_thumb, band_order)

    if type_of == :rgb
      to_run_indices = [:vari, :gli, :ior, :ngri]
    elsif type_of == :nir
      to_run_indices = [:ndvi, :savi, :mnli, :osavi, :bai, :msr, :rdvi, :tdvi, :lai]
    else
      to_run_indices = []
    end

    to_run_indices.each do |vi|
      index_statistics = VegetationIndex.index_statistics(vi.to_s, orthophoto_thumb, band_order)
      
      index_file = "#{Rails.root}/public/indices_statistics/#{vi.to_s}.json"

      File.open(index_file,"w") do |f|
        f.write(JSON.pretty_generate(index_statistics))
      end
    end

  end

  def self.generate_orthophoto_statistics(type_of, orthophoto_path, band_order)
    # check orthophoto existence
    if File.file?(orthophoto_path)

      orthophoto_thumb = orthophoto_path.sub(".png", "_thumb.png")

      # resize and used resized to generate statistics
      # tests showed this is way than on full orthophoto and result are quite similar
      resize_image(orthophoto_path, orthophoto_thumb)

      run_and_store_indices_statistics(type_of, orthophoto_thumb, band_order)
    end
  end

end