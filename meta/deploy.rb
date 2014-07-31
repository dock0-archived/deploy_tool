#!/usr/bin/env ruby

require 'linodeapi'
require 'json'
require 'securerandom'

STACKSCRIPT_ID = 9930
DISTRIBUTION_ID = 128
KERNEL_ID = 138
PV_GRUB_ID = 95

HOSTNAME = ARGV.first || fail('Please supply a hostname')
DEBUG_MODE = ARGV[1].nil? ? 0 : 1

def jobs_running?(linode)
  jobs = API.linode.job.list(linodeid: linode)
  jobs.select { |job| job[:host_finish_dt] == '' }.length > 0
end

def wait_for_jobs(linode)
  while jobs_running? linode
    print '.'
    sleep 5
  end
  puts
end

api_key = `./meta/getkey.rb`
API = LinodeAPI::Raw.new(apikey: api_key)

puts 'Updating stackscript'
API.stackscript.update(
  stackscriptid: STACKSCRIPT_ID,
  distributionidlist: DISTRIBUTION_ID,
  script: File.read(File.expand_path('..', __FILE__) + '/stackscript')
)

linode = API.linode.list.find { |l| l[:label] == HOSTNAME }
linode = linode.fetch(:linodeid) { fail 'Linode not found' }

existing = {
  configs: API.linode.config.list(linodeid: linode),
  disks: API.linode.disk.list(linodeid: linode)
}

if existing.values.reduce(:+).size > 0
  existing.each do |type, things|
    puts "#{type.capitalize}:"
    things.each { |thing| puts "    #{thing[:label]}" }
  end
  puts 'Hit enter to confirm deletion of those configs and disks'
  STDIN.gets
end

API.linode.shutdown(linodeid: linode)
existing[:configs].each do |config|
  API.linode.config.delete(linodeid: linode, configid: config[:configid])
end
existing[:disks].each do |disk|
  API.linode.disk.delete(linodeid: linode, diskid: disk[:diskid])
end

wait_for_jobs linode

devices = [
  ['swap', 128, :swap],
  ['root', 6528, :ext3],
  ['lvm', 40_960, :raw]
]

devices.map! do |name, size, type|
  disk = API.linode.disk.create(
    linodeid: linode,
    label: name,
    size: size,
    type: type
  )
  [name, disk[:diskid]]
end

devices = Hash[devices]

root_pw = SecureRandom.hex(24)
spiped_key = SecureRandom.base64(128)

devices['maker'] = API.linode.disk.createfromstackscript(
  linodeid: linode,
  stackscriptid: STACKSCRIPT_ID,
  distributionid: DISTRIBUTION_ID,
  rootpass: root_pw,
  label: 'maker',
  size: 1536,
  stackscriptudfresponses: {
    name: HOSTNAME,
    debug: DEBUG_MODE,
    spiped_key: spiped_key
  }.to_json
)[:diskid]

config = API.linode.config.create(
  kernelid: KERNEL_ID,
  disklist: devices.values_at('maker', 'swap', 'root', 'lvm').join(','),
  label: 'dock0',
  linodeid: linode
)[:configid]

API.linode.boot(linodeid: linode, configid: config)
sleep 2
wait_for_jobs linode

API.linode.config.update(
  linodeid: linode,
  configid: config,
  helper_depmod: false,
  helper_xen: false,
  helper_disableupdatedb: false,
  devtmpfs_automount: false,
  disklist: devices.values_at('root', 'swap', 'lvm').join(','),
  kernelid: PV_GRUB_ID
)

puts "Success! (maker pw is #{root_pw})"
