namespace :indices do
  desc "Generate Index Statistics for processings."
  task :statistics => :environment do
    
    rgb_orthophoto = "#{Rails.root}/public/rgb_orthophoto/odm_orthophoto.png"
    VegetationIndex.generate_orthophoto_statistics(:rgb, rgb_orthophoto, "RGB")

    nir_orthophoto = "#{Rails.root}/public/nir_orthophoto/odm_orthophoto.png"
    VegetationIndex.generate_orthophoto_statistics(:nir, nir_orthophoto, "RGN")

  end
end