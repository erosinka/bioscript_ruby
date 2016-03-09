Rails.application.routes.draw do

  resources :home do
    collection do
        get 'stats'
    end
  end 
  
  resources :services
 # get ':controller(/:action(/:key))', controller: /requests\/[^\/]+/
 # get ':requests(/:action(/:key))', controller: /requests\/[^\/]+/
    get 'ajax/:action', to: 'ajax#:action', :defaults => { :format => 'json' }

    get 'operations', to: 'plugins#index'
#get 'operations', to: 'plugins#visual_index'
  #get 'home', to: '/home'
  resources :statuses
  resources :param_types
  
  resources :result_types
  resources :jobs
  resources :results
  resources :plugins do
    collection do
        get 'ordered'

    end 
end
 
  resources :requests, param: :key do
    collection do
        post 'fetch'        
    end
  end
  #  member do
  #      get 'build_form'
  #      post 'build_form'
  #  end
  resources :tasks


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#index'
  match 'stats', to: 'home#stats', via: [:get]
  ## root 'plugins#index'
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
