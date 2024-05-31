Rails.application.routes.draw do
  # Routes for schedules
  resources :schedules, only: [:index], defaults: { format: :json }
  get 'schedules/:date', to: 'schedules#show', as: 'schedule_by_date', defaults: { format: :json }

  # Routes for teams
  resources :teams, only: [:index, :show], param: :teamID, defaults: { format: :json }

  # Routes for players
  resources :players, only: [:index, :show], param: :teamID, defaults: { format: :json }

  # Routes for stats
  resources :stats, only: [:index, :show], param: :playerID, defaults: { format: :json }
end
