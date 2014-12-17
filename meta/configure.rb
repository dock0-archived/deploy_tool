#!/usr/bin/env ruby

require 'net/http'

puts 'Waiting for config flag'

conn = Net::HTTP.new('grego.a-rwx.org', 1002)
conn.open_timeout = 2
begin
  sleep 5
  conn.request('/')
rescue Net::OpenTimeout
  retry
end

ssh_options = [
  'StrictHostKeyChecking=no',
  'UserKnownHostsFile=/dev/null',
  'Port=1001',
  'AddressFamily=inet'
]
system "scp #{ssh_options.map { |x| '-o' + x }.join(' ')} build.tar.gz akerl@grego.a-rwx.org:/tmp/"
system "ssh #{ssh_options.map { |x| '-o' + x }.join(' ')} akerl@grego.a-rwx.org touch /tmp/.keep"
