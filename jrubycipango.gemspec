# Gemsec file for jrubycipango gem
  
Gem::Specification.new do |s|
  s.name        = 'jrubycipango'
  s.version     = '0.2.11'
  s.date        = '2014-06-29'
  s.summary     = "JRubyCipango - embedded Cipango HTTP/SIP server"
  s.description = "Create SIP/HTTP applications using embedded Cipago server."
  s.authors     = ["Amer Hasanovic", "Edin Pjanic"] 
  s.email       = ['amer@ictlab.com.ba', 'edin@ictlab.com.ba']

  s.files       =  ["lib/jrubycipango.rb", 
                    "lib/jrubycipango/factory.rb"]

  Dir["lib/jrubycipango/jars/*.jar"].each { |jar| s.files << jar }
  Dir["lib/jrubycipango/jars/sip/*.jar"].each { |jar| s.files << jar }
  Dir["lib/jrubycipango/jars/jetty/*.jar"].each { |jar| s.files << jar }
  s.require_paths      = ["lib"] 
  s.homepage    = 'http://ictlab.com.ba'
end


