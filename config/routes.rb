RoRmaily::Engine.routes.draw do
  get ":token", to: "tokens#get", as: :token
end

RoRmaily::Engine.routes.url_helpers.class.module_eval do
  def unsubscribe_url(subscription, *args)
    options = args.extract_options! || {}
    options = options.reverse_merge(controller: "/ror_maily/tokens", action: "get", token: subscription.token)

    RoRmaily::Engine.routes.url_helpers.url_for(options)
  end
end
