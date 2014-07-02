# Rails: ne zaboraviti u config/environments/production.rb postaviti config.assets.compile=true
module JRubyCipango
  module Factory
    ['org.jruby.rack.DefaultRackApplicationFactory',
      'org.jruby.rack.SharedRackApplicationFactory',
      'org.jruby.rack.RackServletContextListener',
      'org.jruby.rack.rails.RailsServletContextListener', 
      'org.jruby.Ruby'
    ].each {|c| java_import c }

    class JRCRackFactory < DefaultRackApplicationFactory
      field_accessor :rackContext
      def newRuntime
        runtime = Ruby.get_global_runtime 
        $servlet_context=rackContext
        require 'rack/handler/servlet'
        return runtime
      end
    end

    class JRCRackListener < RackServletContextListener
      field_reader :factory
      def newApplicationFactory(context)
        if factory
          return factory
        else
          return (
            SharedRackApplicationFactory.new(JRCRackFactory.new)
          )
        end
      end
    end

  end 
end 
