#!/usr/bin/env ruby

require 'yaml'
require 'securerandom'
require_relative 'lib/api'
require_relative 'lib/helpers'

HOSTNAME = ARGV.first || fail('Please supply a hostname')
CONFIG = YAML.load(File.read('config.yaml'))
API_IDS = CONFIG['api_ids']

wrapper = API.new HOSTNAME

puts 'Updating StackScript'
wrapper.api.stackscript.update(
  stackscriptid: API_IDS['stackscript'],
  distributionidlist: API_IDS['distribution'],
  script: File.read(CONFIG['stackscript'])
)

wrapper.delete_all!
wrapper.wait_for_jobs

puts 'Creating new disks'
ROOT_PW = SecureRandom.hex(24)
root_id = api.create_from_stackscript(
  stackscriptid: API_IDS['stackscript'],
  distributionid: API_IDS['distribution'],
  rootpass: ROOT_PW,
  label: 'meta_dock0',
  size: 8192,
  stackscriptudfresponses: '{}'
)

config_id = wrapper.create_config(
  kernelid: API_IDS['stock_kernel'],
  disklist: "#{root_id},#{API_IDS['finnix']}",
  label: 'meta_dock0',
)

puts 'Booting meta image'
wrapper.boot(config_id)

Helpers.wait_for_response "#{HOSTNAME}.#{CONFIG['domain']}", 80

wrapper.shutdown

wrapper.delete_image_by_label('meta_dock0')
image_id = wrapper.imagize(diskid: root_id)

puts "New image created: #{image_id}"
