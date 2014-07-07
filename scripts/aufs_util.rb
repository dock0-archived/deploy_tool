##
# Install aufs-util package on build system and new system

require 'fileutils'
require 'open-uri'

url = 'https://github.com/dock0/aufs-util/releases/download/latest/'

puts 'Downloading the aufs-util tarball'
File.open('/tmp/aufs-util.tar.xz', 'w') do |fh|
  open(url + 'aufs-util.tar.xz', 'rb') { |request| fh.write request.read }
end

['/', "#{@config['paths']['mount']}/"].each do |root|
  puts "Installing aufs-util to #{root}"
  system "tar -xf /tmp/aufs-util.tar.xz -C #{root} --keep-directory-symlink"
end
