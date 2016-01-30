Rails.application.routes.draw do

  # This line mounts Forem's routes at /forums by default.
  # This means, any requests to the /forums URL of your application will go to Forem::ForumsController#index.
  # If you would like to change where this extension is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Forem relies on it being the default of "forem"
  mount Forem::Engine, :at => '/forums'

  root 'home#index'

  get '/t/:template' => 'home#template'
  get '/docs' => 'home#docs'
  get '/docs/:page' => 'home#docs'
  get '/map/:id' => 'home#map'

  get "/404" => "errors#not_found"
  get "/422" => "errors#non_processable"
  get "/500" => "errors#exception"

  devise_for :users, controllers: { registrations: "registrations" }
  
  namespace :api do
    mount_devise_token_auth_for 'User', at: 'auth'
    
    get '/' => 'reports#index', :defaults => { :format => 'json' }
    
    get '/alliances' => 'reports#alliances', :defaults => { :format => 'json' }
    
    get '/immortals' => 'reports#immortals', :defaults => { :format => 'json' }
    
    get '/user' => 'users#show', :defaults => { :format => 'json' }
    
    get '/quests' => 'reports#quests', :defaults => { :format => 'json' }
    
    get '/game' => 'games#show', :defaults => { :format => 'json' }
    get '/games' => 'games#index', :defaults => { :format => 'json' }
    
    get '/character' => 'characters#show', :defaults => { :format => 'json' }
    post '/character' => 'characters#create', :defaults => { :format => 'json' }
    
    get '/map/:x/:y' => 'reports#map', :defaults => { :format => 'json' }
    
    get 'status/:id' => 'actions#status', :defaults => { :format => 'json' }
    delete 'status/:id' => 'actions#cancel', :defaults => { :format => 'json' }
    
    get 'battles' => 'reports#battle_report', :defaults => { :format => 'json' }
    get 'battles/:id' => 'reports#battle_report', :defaults => { :format => 'json' }

    get 'recipients' => 'messages#recipients', :defaults => { :format => 'json' }
    get 'messages' => 'messages#index', :defaults => { :format => 'json' }
    get 'messages/:id' => 'messages#show', :defaults => { :format => 'json' }
    post 'messages' => 'messages#create', :defaults => { :format => 'json' }
    delete 'messages/:id' => 'messages#destroy', :defaults => { :format => 'json' }

    get ':type/:id/events' => 'reports#events', :defaults => { :format => 'json' }
    get ':type/:id/market' => 'reports#market', :defaults => { :format => 'json' }
    get ':type/:id/notifications' => 'reports#notifications', :defaults => { :format => 'json' }
    get ':type/:id' => 'reports#show', :defaults => { :format => 'json' }
    post ':type/:id/:action_type' => 'actions#create', :defaults => { :format => 'json' }
  end
end
