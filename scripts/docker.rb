##
# Roll the new kernel

require 'fileutils'
require 'open-uri'

if @config['docker_url']
  File.open("/usr/local/sbin/docker", 'wb') do |fh|
    open(@config['docker_url'], 'rb') { |request| fh.write request.read }
  end
  File.chmod '0755', '/usr/local/sbin/docker'
else
  FileUtils.ln_sf '/usr/bin/docker', '/usr/local/sbin/docker'
end
