#!/usr/bin/env ruby

require 'dock0'
require_relative 'lib/helpers'

HOSTNAME = ARGV.first || fail('Please supply a hostname')
CONFIG_FILES = ['config.yaml', "configs/#{HOSTNAME}.yaml"]
CONFIG = CONFIG_FILES.each_with_object({}) do |file, obj|
  next unless File.exist? file
  obj.merge! YAML.load(File.read(file))
end

puts 'Building config tarball'
Dock0.easy_mode :Config, CONFIG_FILES

puts 'Waiting for config flag'
Helpers.wait_for_response "#{HOSTNAME}.#{CONFIG['domain']}", 1002

puts 'Sending tarball'
ssh_options = [
  'StrictHostKeyChecking=no',
  'UserKnownHostsFile=/dev/null',
  'Port=1001',
  'AddressFamily=inet'
].map { |x| '-o' + x }.join(' ')
host = "#{CONFIG['ssh_user']}@#{HOSTNAME}.#{CONFIG['domain']}"
system "scp #{ssh_options} build-#{HOSTNAME}.tar.gz #{host}:/tmp/build.tar.gz"
system "ssh #{ssh_options} #{host} touch /tmp/.done"

puts 'Done!'
