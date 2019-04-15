class VegetationIndexController < ApplicationController
  def index
    tile = params[:tile]
    tile_path = "#{Rails.root}/public/#{tile}"
  
    data = VegetationIndex.apply_index(params[:index], tile_path, params[:min], params[:max], params[:band_order])
    
    send_data(data.write_to_buffer(".png"), type: "image/png", disposition: "inline")
  end
end
