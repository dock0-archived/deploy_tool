#!/usr/bin/env ruby

require 'linodeapi'
require 'json'
require 'yaml'
require 'securerandom'
require 'fileutils'

HOSTNAME = ARGV.first || fail('Please supply a hostname')
CONFIG_FILES = ['config.yaml', "configs/#{HOSTNAME}.yaml"]
CONFIG = CONFIG_FILES.each_with_object({}) do |file, obj|
  next unless File.exist? file
  obj.merge! YAML.load(File.read(file))
end
API_IDS = CONFIG['api_ids']

def jobs_running?(linodeid)
  jobs = API.linode.job.list(linodeid: linodeid)
  jobs.select { |job| job[:host_finish_dt] == '' }.length > 0
end

def wait_for_jobs(linodeid)
  while jobs_running? linodeid
    print '.'
    sleep 5
  end
  puts
end

api_key = `./meta/getkey.rb`
API = LinodeAPI::Raw.new(apikey: api_key)

API.stackscript.update(
  stackscriptid: API_IDS['stackscript'],
  distributionidlist: API_IDS['distribution'],
  script: File.read(CONFIG['stackscript'])
)

linode = API.linode.list.find { |l| l[:label] == HOSTNAME }
LINODE_ID = linode.fetch(:linodeid) { fail 'Linode not found' }

existing = {
  configs: API.linode.config.list(linodeid: LINODE_ID),
  disks: API.linode.disk.list(linodeid: LINODE_ID)
}

API.linode.shutdown(linodeid: LINODE_ID)
existing[:configs].each do |config|
  API.linode.config.delete(linodeid: LINODE_ID, configid: config[:configid])
end
existing[:disks].each do |disk|
  API.linode.disk.delete(linodeid: LINODE_ID, diskid: disk[:diskid])
end

wait_for_jobs LINODE_ID

DISKS = {}
CONFIG['disks'].each do |disk|
  disk = Hash[disk.map { |k, v| [k.to_sym, v] }]
  result = API.linode.disk.create disk.merge(linodeid: LINODE_ID)
  DISKS[disk[:label].to_sym] = result[:diskid]
end

ROOT_PW = SecureRandom.hex(24)

DISKS[:maker] = API.linode.disk.createfromstackscript(
  linodeid: LINODE_ID,
  stackscriptid: API_IDS['stackscript'],
  distributionid: API_IDS['distribution'],
  rootpass: ROOT_PW,
  label: 'maker',
  size: 1024,
  stackscriptudfresponses: { name: HOSTNAME }.to_json
)[:diskid]

CONFIG_ID = API.linode.config.create(
  kernelid: API_IDS['stock_kernel'],
  disklist: DISKS.values_at(:maker, :swap, :root, :lvm).join(','),
  label: 'dock0',
  linodeid: LINODE_ID
)[:configid]

API.linode.boot(linodeid: LINODE_ID, configid: CONFIG_ID)
sleep 2
wait_for_jobs LINODE_ID

API.linode.config.update(
  linodeid: LINODE_ID,
  configid: CONFIG_ID,
  helper_depmod: false,
  helper_xen: false,
  helper_disableupdatedb: false,
  devtmpfs_automount: false,
  disklist: DISKS.values_at(:root, :swap, :lvm).join(','),
  kernelid: API_IDS['pvgrub']
)

puts "Success! (maker pw is #{ROOT_PW})"
