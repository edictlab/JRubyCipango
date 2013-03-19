require 'rubygems'
require 'jrubycipango'

require './ruby_sip_servlet.rb'

myserver = JRubyCipango::CipangoServer.new    # create server instance with default settings
myserver.add_sip_servlet MySipServlet.new     # add Ruby SIP servlet (default options)
myserver.add_rackup                           # add Rack application (default options)

myserver.start


