module RoRmaily
  class TokensController < RoRmaily::ApplicationController
    def get
      @subscription = RoRmaily::Subscription.find_by_token(params[:token])
      @subscription.try(:deactivate!)

      redirect_to RoRmaily.token_redirect.try(:call, self, @subscription) || "/", 
        notice: @subscription ? t('ror_maily.subscription.deactivated') : t('ror_maily.subscription.undefined_token')
    end
  end
end
