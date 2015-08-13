module RoRmaily
  class Engine < ::Rails::Engine
    isolate_namespace RoRmaily

    config.generators do |g|
      g.test_framework      :rspec,         fixture: false
      g.fixture_replacement :factory_girl,  dir: 'spec/factories'
    end

    config.to_prepare do
      require_dependency 'ror_maily/model_extensions'

      RoRmaily.contexts.each do|n, c|
        if c.model
          unless c.model.included_modules.include?(RoRmaily::ModelExtensions)
            c.model.send(:include, RoRmaily::ModelExtensions)
          end
        end
      end
    end
  end
end
