##
# Roll the new kernel

require 'fileutils'
require 'open-uri'

url = @config['docker_url']
path = '/usr/local/sbin/docker'

if url
  File.open(path, 'wb') do |fh|
    open(url, 'rb') { |request| fh.write request.read }
  end
  File.chmod 0755, path
else
  FileUtils.ln_sf '/usr/bin/docker', path
end
