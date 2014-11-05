##
# Roll the new kernel

require 'fileutils'
require 'open-uri'

url = @config['docker_url']
path = "#{@config['paths']['mount']}/usr/local/sbin/docker"

if url
  puts "Downloading #{url} to #{path}"
  File.open(path, 'wb') do |fh|
    open(url, 'rb') { |request| fh.write request.read }
  end
  File.chmod 0755, path
else
  FileUtils.ln_sf '/usr/bin/docker', path
end
