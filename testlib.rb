require 'net/http'
require 'json'

module Test

  def self.login
    "user-login"
  end

  def self.key
   "key-text"
  end

  def self.send data
    uri = URI('http://localhost:81/api')
    http = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = data.to_json
    #puts req.body
    res = http.request(req)
    JSON.parse(res.body,symbolize_names: true)
  end

  def self.report val
    if val
      "\t ... \e[0;32mpassed\e[0m"
    else
      "\t ... \e[0;31mfailed\e[0m"
    end
  end

  def self.verify name, query, opts={}

    print "#{name}"
    answer = send query
    puts " --> #{answer} " if opts[:loud]

    puts " error: #{answer[:errors].join(', ')}" if answer[:result] == "error"

    begin
      result = yield answer
    rescue
      result = false
    end

    puts report result

  end

end
