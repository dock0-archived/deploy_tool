require 'net/http'
require 'resolv'

##
# Add helper for waiting for response
module Helpers
  class << self
    def wait_for_response(hostname, port)
      ip = Resolv.getaddress hostname
      conn = Net::HTTP.new(ip, port)
      conn.open_timeout = 2
      req = Net::HTTP::Get.new '/'
      begin
        conn.request req
      rescue Net::OpenTimeout, Errno::ECONNREFUSED
        sleep 5
        retry
      end
    end
  end
end
