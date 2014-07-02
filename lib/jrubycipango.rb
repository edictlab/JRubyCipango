
# jrubyciango gem
# Embedding Cipango HTTP/SIP application server into a JRuby application

require 'java'

# --- Cipango/Jetty and JRuby Rack jars -----
dir = File.dirname(File.expand_path(__FILE__)) 
Dir[dir + "/jrubycipango/jars/*.jar"].each { |jar| require jar }
Dir[dir + "/jrubycipango/jars/sip/*.jar"].each { |jar| require jar }
Dir[dir + "/jrubycipango/jars/jetty/*.jar"].each { |jar| require jar }

require 'jrubycipango/factory'

module JRubyCipango
  %w[
  org.cipango.server.handler.SipContextHandlerCollection
  org.cipango.server.Server
  org.cipango.dar.DefaultApplicationRouter
  org.cipango.server.bio.UdpConnector
  org.cipango.server.bio.TcpConnector
  org.cipango.server.SipConnector
  org.cipango.sipapp.SipAppContext
  org.cipango.servlet.SipServletHolder
  org.eclipse.jetty.server.bio.SocketConnector
  org.eclipse.jetty.server.Connector
  org.eclipse.jetty.server.Handler
  org.eclipse.jetty.servlet.ServletHolder
  org.eclipse.jetty.servlet.DefaultServlet
  org.eclipse.jetty.servlet.FilterMapping
  java.util.HashMap
  ].each {|cl| java_import cl }


  class CipangoServer  
    attr_accessor :context_path, :resource_base

    # Initialize converged server's instance
    # Options:
    #   :host_ip_address
    #   :http_port
    #   :sip_port
    #   :context_path
    #   :resource_base
    #   :route_outgoing_requests
    def initialize(params={})
      @host_ip_address = params[:host_ip_address] || '0.0.0.0'
      @http_port = params[:http_port]             || 8080
      @sip_port = params[:sip_port]               || 5060
      @route_outgoing_requests = params[:route_outgoing_requests]  || false

      @context_path = params[:context_path]       || '/'
      @resource_base = params[:resource_base]     || '.' 

      @http_servlets = []
      @sip_servlets = []
      @has_rack_app = false
    end

    # Add http servlet
    def add_http_servlet http_app, params = {}
      @http_servlets << {
        :app => http_app, 
        :init_params => params[:init_params] || {}, 
        :context_path => params[:context_path] || '/*',
        :servlet_name => params[:servlet_name] || nil
      } if http_app  
    end

    # Add rack application
    # Options:
    #   :rackup_file - default 'config.ru'
    #   :static_path - path to static content, default '/public'

    def add_rackup rackup_options = {}
      rackup_options[:rackup_file] ||= 'config.ru'
      rackup_options[:static_path] ||= '/public'
      @resource_base = ".#{rackup_options[:static_path]}"
      @rackup_options = rackup_options
      @has_rack_app = true
    end

    # Add SIP servlet object
    # :options => {:is_event_listener => false} 
    # If :is_event_listener is true the servlet must include a Java Sip listener interface(s) (javax.servlet.sip.SipSessionListener, TimerListener or other)
    
    def add_sip_servlet sip_servlet, options={}
      options[:is_event_listener] ||= false
      options[:servlet_name] ||= nil
      @sip_servlets << {:servlet => sip_servlet, :options => options} if sip_servlet
    end

    # Start the Cipango server

    def start
      @cipango = cipango = Server.new

      # Don't open SIP ports if there is no SIP servlets
      if @sip_servlets.size > 0
        udp_sip = UdpConnector.new
        tcp_sip = TcpConnector.new
        udp_sip.host = @host_ip_address
        udp_sip.port = @sip_port
        tcp_sip.host = udp_sip.host
        tcp_sip.port = udp_sip.port
        cipango.connector_manager.connectors = [udp_sip, tcp_sip].to_java(SipConnector) 
      end

      tcp_http = SocketConnector.new
      tcp_http.port = @http_port
      tcp_http.host = @host_ip_address
      cipango.connectors = [tcp_http].to_java(Connector)

      context = SipAppContext.new
      context.context_path = @context_path
      context.resource_base = @resource_base 

       
      $sip_servlet_context = context.servlet_context

      context.set_init_parameter('jruby.max.runtimes', '1')
      #context.set_init_parameter('org.cipango.dar.routeOutgoingRequests', 'false')
      
      #context.set_init_parameter('org.eclipse.jetty.servlet.Default.resourceCache', '0')
      #context.set_init_parameter('org.eclipse.jetty.servlet.Default.relativeResourceBase', '/public')
         

      if @has_rack_app
        context.set_init_parameter('rackup', File.read(@rackup_options[:rackup_file]))
        context.add_filter("org.jruby.rack.RackFilter", "/*", FilterMapping::DEFAULT)
        context.add_event_listener( Factory::JRCRackListener.new )
      end

      @http_servlets.each do |servlet|
        #servlet_holder = ServletHolder.new(servlet[:servlet_name], servlet[:app] )
        servlet_holder = ServletHolder.new(servlet[:app] )
        servlet_holder.name = servlet[:servlet_name] if servlet[:servlet_name]
        params = servlet[:init_params]
        params.each{|k, v| servlet_holder.set_init_parameter(k, v) }

        context.add_servlet(servlet_holder, servlet[:context_path])
      end

       # It has to be a custom listener, not the Rack listener, in order to be in the same runtime and have access to the Rack application's namespace.
       # context.add_event_listener( Factory::RackServletContextListener.new )

      @sip_servlets.each do |servlet_data|
        servlet_holder = SipServletHolder.new(servlet_data[:servlet])
        servlet_holder.name = servlet_data[:options][:servlet_name] if servlet_data[:options][:servlet_name]
        context.add_sip_servlet(servlet_holder)
        context.add_event_listener(servlet_data[:servlet]) if servlet_data[:options][:is_event_listener]
      end

      context_collection = SipContextHandlerCollection.new
      context_collection.add_handler(context)

      dar = DefaultApplicationRouter.new
      cipango.application_router = dar
      dar.route_outgoing_requests = @route_outgoing_requests

      cipango.handler = context_collection
      cipango.start
      cipango.join
    end
  end
end

