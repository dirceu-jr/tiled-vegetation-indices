Rails.application.routes.draw do
  get '/vegetation_index', to: 'vegetation_index#index', as: 'vegetation_index'
end
