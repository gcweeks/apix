Rails.application.routes.draw do
  post '/graphql', to: 'graphql#execute'
  root 'api#version'

  get  'test'    => 'api#request_get'
  post 'test'    => 'api#request_post'
  get  'auth'    => 'api#auth'
  post 'support' => 'api#support'
  post 'reset'   => 'api#reset'

  scope 'x' do
    scope ':user_name' do
      scope ':repo_name' do
        scope ':node_label' do
          get    '/'       => 'graph#index'
          post   '/'       => 'graph#create'
          post   '/search' => 'graph#search'
          get    '/:id'    => 'graph#show'
          put    '/:id'    => 'graph#update'
          delete '/:id'    => 'graph#destroy'
        end
      end
    end
  end

  get  'me' => 'users#show_me'
  put  'me' => 'users#update_me'
  get  'preferences' => 'users#get_prefs'
  post 'preferences' => 'users#set_prefs'
  resources :users, except: %i(index), param: :name do
    resources :repos, param: :name do
      resources :nodes
      resources :relationships
      resources :interfaces
    end
  end
end
