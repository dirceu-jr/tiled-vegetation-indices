Rails.application.routes.draw do
  get '/vegetation_index', to: 'vegetation_index#index', as: 'vegetation_index'
  get '/map', to: 'map#index', as: 'map_index'
  
  root to: "map#index"
end
