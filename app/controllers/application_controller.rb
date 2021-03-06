class ApplicationController < ActionController::Base
  include Authentication
  include LastSeen
  include Pundit
  include ApiAnalytics
  include WithBadges
  include RateLimited

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def self.actions_without_auth(*actions)
    skip_before_action :ensure_signed_in, only: actions
    after_action :verify_authorized, except: actions
  end

  private
  def user_not_authorized
    head :forbidden
  end
end
