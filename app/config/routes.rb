Rails.application.routes.draw do
  root 'api#version'

  get  '/test' => 'api#request_get'
  post '/test' => 'api#request_post'

  scope 'x' do
    scope ':node_label' do
      get    '/'       => 'api#index'
      post   '/'       => 'api#create'
      post   '/search' => 'api#search'
      get    '/:id'    => 'api#show'
      put    '/:id'    => 'api#update'
      delete '/:id'    => 'api#destroy'
    end
  end

  scope 'nodes' do
    get    '/'    => 'nodes#index'
    post   '/'    => 'nodes#create'
    get    '/:id' => 'nodes#show'
    put    '/:id' => 'nodes#update'
    delete '/:id' => 'nodes#destroy'
  end

  scope 'relationships' do
    post   '/'    => 'relationships#create'
    get    '/:id' => 'relationships#show'
    put    '/:id' => 'relationships#update'
    delete '/:id' => 'relationships#destroy'
  end
end
