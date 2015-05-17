#!/usr/bin/env ruby

require 'net/http'
require 'resolv'
require 'dock0'

HOSTNAME = ARGV.first || fail('Please supply a hostname')
CONFIG_FILES = ['config.yaml', "configs/#{HOSTNAME}.yaml"]
CONFIG = CONFIG_FILES.each_with_object({}) do |file, obj|
  next unless File.exist? file
  obj.merge! YAML.load(File.read(file))
end
VERSION = CONFIG['version'] || fail('No version specified')

puts 'Building config tarball'
Dock0.easy_mode :Config, CONFIG_FILES

puts 'Waiting for config flag'
ip = Resolv.getaddress "#{HOSTNAME}.#{CONFIG['domain']}"
conn = Net::HTTP.new(ip, 1002)
conn.open_timeout = 2
req = Net::HTTP::Get.new '/'
begin
  conn.request req
rescue Net::OpenTimeout, Errno::ECONNREFUSED
  sleep 5
  retry
end

puts 'Sending tarball'
ssh_options = [
  'StrictHostKeyChecking=no',
  'UserKnownHostsFile=/dev/null',
  'Port=1001',
  'AddressFamily=inet'
].map { |x| '-o' + x }.join(' ')
host = "#{CONFIG['ssh_user']}@#{HOSTNAME}.#{CONFIG['domain']}"
source = "build-#{HOSTNAME}.tar.gz"
target = "/run/vm/bootmnt/sources/config/#{VERSION}"
system "scp #{ssh_options} #{source} #{host}:#{target}"
system "ssh #{ssh_options} #{host} touch /tmp/.done"

puts 'Done!'
