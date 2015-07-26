#!/usr/bin/env ruby

require 'linodeapi'
require 'yaml'
require 'securerandom'
require 'meld'
require_relative 'helpers'

HOSTNAME = ARGV.first || fail('Please supply a hostname')
CONFIG_FILES = ['config.yaml', "configs/#{HOSTNAME}.yaml"]
CONFIG = CONFIG_FILES.each_with_object({}) do |file, obj|
  next unless File.exist? file
  obj.deep_merge! YAML.load(File.read(file))
end
API_IDS = CONFIG['api_ids']

wrapper = APIWrapper.new

auts 'Updating StackScript'
wrapper.api.stackscript.update(
  stackscriptid: API_IDS['stackscript'],
  distributionidlist: API_IDS['distribution'],
  script: File.read(CONFIG['stackscript'])
)

wrapper.delete_all!
wrapper.wait_for_jobs

puts 'Creating new disks'
DISKS = {}
CONFIG['disks'].each do |disk|
  disk = Hash[disk.map { |k, v| [k.to_sym, v] }]
  DISKS[disk[:label].to_sym] = wrapper.create_disk disk
end

ROOT_PW = SecureRandom.hex(24)

DISKS[:maker] = wrapper.create_from_stackscript(
  stackscriptid: API_IDS['stackscript'],
  distributionid: API_IDS['distribution'],
  rootpass: ROOT_PW,
  label: 'maker',
  size: 1024,
  stackscriptudfresponses: '{}'
)[:diskid]
DISKS[:finnix] = API_IDS['finnix']

CONFIG_ID = wrapper.create_config(
  kernelid: API_IDS['stock_kernel'],
  disklist: DISKS.values_at(:maker, :finnix, :root, :lvm).join(','),
  label: 'dock0',
)

puts 'Booting maker image'
wrapper.boot(CONFIG_ID)

wrapper.config_update(
  configid: CONFIG_ID,
  helper_depmod: false,
  helper_distro: false,
  helper_disableupdatedb: false,
  helper_network: false,
  devtmpfs_automount: false,
  disklist: DISKS.values_at(:root, :lvm).join(','),
  kernelid: API_IDS["#{CONFIG['hypervisor']}_kernel"]
)

puts "Success! (maker pw is #{ROOT_PW})"

system "./meta/configure.rb #{HOSTNAME}"
