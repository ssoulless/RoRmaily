module RoRmaily
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a RoRmaily initializer and copy locale files to your application."

      def copy_initializer
        template "ror_maily.rb", "config/initializers/ror_maily.rb"
      end

      def copy_locale
        copy_file "../../../config/locales/en.yml", "config/locales/ror_maily.en.yml"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
