Rails.application.routes.draw do
  root 'api#version'
  resources :users, only: [:create]

  get  'test' => 'api#request_get'
  post 'test' => 'api#request_post'
  get  'auth' => 'api#auth'

  scope 'x' do
    scope ':node_label' do
      get    '/'       => 'graph#index'
      post   '/'       => 'graph#create'
      post   '/search' => 'graph#search'
      get    '/:id'    => 'graph#show'
      put    '/:id'    => 'graph#update'
      delete '/:id'    => 'graph#destroy'
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

  # Model-specific calls (other than those created by resources)
  scope 'users' do
    scope 'me' do
      get    '/'                        => 'users#get_me'
      put    '/'                        => 'users#update_me'
      post   'support'                  => 'users#support'
    end
  end
end
