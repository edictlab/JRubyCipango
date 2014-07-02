# JRubyCipango

Embedding Cipango HTTP/SIP application server into a JRuby application

## Installation

Install `jrubycipango` gem as any other JRuby gem:

      $ jruby -S gem install jrubycipango

## Features and usage

This gem does not work in MRI Ruby. It only works in JRuby since it is based on Java libraries.

This gem is a wrapper for Java based Cipango SIP/HTTP Servlet Application Server. With this gem, it is possible to create HTTP and SIP servlets applications in Ruby, as well as JRuby Rack applications, and all in one JRuby runtime.

This wrapper is implemented in `JRubyCipango::CipangoServer` Ruby class.


You can read about concepts behind this gem in our papers. PDF files are available at [this location](http://scholar.google.com/citations?user=7RoQiiQAAAAJ).

We highly recomend you to see also [`sipfsm`](http://github.com/edictlab/SipFSM) gem in order to simplify the description of the SIP call flows inside the application. 

### Setting up and starting the server

In order to use this gem you have to require it in your application:

    require 'jrubycipango'

This instruction loads all Java libraries required for Cipango/Jetty server.

Now we can create a server instance:

    myserver = JRubyCipango::CipangoServer.new

This constructor receives an optional Hash parameter with the following keys:

- `:host_ip_address` - IP address to listen to, default value is `0.0.0.0`,
- `:http_port` - IP port for listening to HTTP traffic, default value is `8080`,
- `:sip_port` - IP port for lintening to SIP traffic, default value is `5060`,
- `:context_path` - HTTP application context path, default value is `'/'` and
- `:resource_base` - root for the resurce base, default value is `'.'`.
- `:route_outgoing_requests` - configure the DAR to process outgoing SIP requests, default value is `false`.

There are three instance methods of `CipangoServer` class for adding HTTP and SIP servlets to the server instance. All types of servlets can be implemented in Ruby language.

For understanding SIP and HTTP servlets please see [cipango.org](http://cipango.org), [Wikipedia article](http://en.wikipedia.org/wiki/Java_Servlet) or other.

#### Adding a standard HTTP servlet:
    myserver.add_http_servlet http_app, options

where:

- `http_app` is a HTTP servlet instance, 
- `options` is an options hash with the following keys:
  - `:servlet_name` is a servlet's name,
  - `:context_path` is a servlet context path (default value is `'/*'`) and
  - `:init_params` are the servlet's initialization parameters given as a Ruby Hash (optional).

#### Adding a JRuby Rack application

    myserver.add_rackup rackup_options

where `rackup_options` is an optional Hash with the following keys:

  - `:rackup_file` - name of rackup file, default is `'config.ru'`,
  - `:static_path` - relative path to the static content, default is `'/public'`.

#### Adding a SIP servlet

    myserver.add_sip_servlet sip_servlet, options

where:

- `sip_sevlet` is an instance of a SIP servlet class, which can be a Ruby SIP sevlet class and
- `options` is a Hash with options:
  - `:is_event_listener` tells whether the servlet is configured to be an event listener. Supported with possible values `true` or `false` (default). In order for Ruby SIP servlet to be event listener it must implement appropriate Java interface.
  - `:servlet_name` is the SIP servlet's name.

### Example

In this example we create an application that acts as a SIP registrar and SIP proxy server for registered users. Users are administered using web interface built in Ruby on Rails.

This application is extremely simple but has enough functionality to be used as SIP server on a local network where SIP clients can be VoIP softphones or dedicated VoIP phones.

#### Web part: Rails application (administration UI)

Here we create Rails project for users administration.
Please see also [this article](http://sdiwc.net/digital-library/exploring-ruby-and-java-interoperability-for-buildingconverged-web-and-sip-applications).

Create the project using a JRuby template and name it `registrar`. 

    $ jruby -S rails new registrar --template http://jruby.org

Move to `registrar` directory:

    $ cd registrar/

Now let's create a UI and model for users. We need only username, first and last name. For simplicity, forget about password.

    $ jruby -S rails generate scaffold sip_user user_name:string first_name:string last_name:string

When user's SIP client registers to the regstrar we have to keep his location. Let's generate an appropriate model:

    $ jruby -S rails generate model registration location:string sip_user:references

Now, we need to create the
other side of the association by changing
the generated `SipUser` class definition, saved in the file `’app/models/sip user.rb’`. Add the following line into the model definition:

    has_one :registration, :dependent => :destroy

Now migrate a database in order to create tables:

    $ jruby -S rake db:migrate RAILS_ENV=production

There is one more thing. We have to instruct Rails to compile assets. Open the file `'config/environments/production.rb'` and find settings for `config.assets.compile`! By default, it is set to `false`. Change it to `true`:

    config.assets.compile = true

Web part of the application is setup and ready.

#### SIP part: Ruby SIP servlet

Now, lets have a simple registrar and proxy Ruby SIP servlet:

      # file 'ruby_sip_servlet.rb'
      class MySipServlet < Java::javax.servlet.sip.SipServlet
      
        def doRegister(request)
          username = request.from.uri.user
          address = request.remote_addr 
          port = request.remote_port
          remote_uri = "sip:#{username}@#{address}:#{port}"
      
          puts "REGISTRATION: #{remote_uri}"
      
          user = SipUser.find_by_user_name(username)
          if user 
            exp = request.get_header('Expires')
            if !exp
              c = request.get_header('Contact')
              c.grep(/expires=(\d+)/)
              exp = $1
            end
            exp = exp.to_i
            if exp == 0
              reg = Registration.find_by_sip_user_id(user.id)
              reg.destroy if reg
              puts "Unregistered"
            else
              reg = Registration.find_or_create_by_sip_user_id_and_location(user.id, remote_uri)
              reg.location = remote_uri
              reg.save
              puts "Registered"
            end
            request.create_response(200).send
          else
            puts "Not registered"
            request.create_response(404).send
          end
        end
      
        def doInvite req
          username = req.get_to.get_uri.get_user
          puts "INVITE user: #{username}"
          user = SipUser.find_by_user_name(username)
          if user
            reg = user.registration if user
      
            if reg
              factory = $servlet_context.get_attribute('javax.servlet.sip.SipFactory')
              uri = factory.create_uri(reg.location)
              puts "Proxying to #{uri}..."
              req.get_proxy.proxy_to(uri)
            else
              puts '480: User not available.'
              req.create_response(480).send
            end
      
          else
            puts '404: User not found.'
            req.create_response(404).send
          end
        end
      end 

The servlet accepts users' SIP clients registrations, checks users against the database created in Rails project and registers them if they exists.

This servlet is a SIP proxy server, too. When the SIP client sends an INVITE request, the servlet checks database for destination user and his location and proxies the request to the callee. In case the callee user does not exist or not currently available it sends back appropriate 4xx response .

Let's save file `ruby_sip_servlet.rb` into the root directory of the Rails project.

In the same directory, create file `start_app.rb` where we setup and start the instance of the Cipango server:

      require 'rubygems'
      require 'jrubycipango'
      
      require './ruby_sip_servlet.rb'
      
      myserver = JRubyCipango::CipangoServer.new
      myserver.add_sip_servlet MySipServlet.new
      myserver.add_rackup 
      
      myserver.start

Start the application by issuing command:

    $ jruby start_app.rb

The registered users can now setup their SIP clients to point to our application in order to make calls to other registered users.

