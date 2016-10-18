require "net/http"
require "json"
require "uri"

module RiakCS
  USER_RESOURCE_PATH = "riak-cs/user"

  def self.create_admin_user(name, email, fqdn, port, scheme, verify_mode, ca_file)
    uri           = URI.parse("#{scheme}://#{fqdn}:#{port}/#{USER_RESOURCE_PATH}")
    request       = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
    request.body  = {
      "email" => email,
      "name"  => name
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)

    if scheme == "https"
      verify_mode = case verify_mode
      when "peer"
        OpenSSL::SSL::VERIFY_PEER
      when "none"
        OpenSSL::SSL::VERIFY_NONE
      else
        OpenSSL::SSL::VERIFY_PEER
      end

      http.use_ssl = true
      http.verify_mode = verify_mode
      http.ca_file = ca_file unless ca_file.empty?
    end

    response = http.start do |h|
      h.request(request)
    end
    json = JSON.parse(response.body)

    [ json["key_id"], json["key_secret"] ]
  rescue => e
    Chef::Log.warn "Error occurred trying to create admin user: #{e.inspect}"
    raise e
  end
end
