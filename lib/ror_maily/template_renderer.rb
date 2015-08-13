module RoRmaily
  module TemplateRenderer
    def self.included(base)
      base.send :include, RoRmaily::TemplateRenderer::InstanceMethods
    end

    module InstanceMethods
      protected 

      def perform_template_rendering drop, template
        template = Liquid::Template.parse(template)
        template.render! drop
      end
    end
  end
end
