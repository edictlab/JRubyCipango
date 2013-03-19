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

