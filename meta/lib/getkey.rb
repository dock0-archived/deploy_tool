#!/usr/bin/env ruby

require 'keychain'
require 'highline/import'
require 'linodeapi'

keychain_path = ENV['DOCK0_KEYCHAIN'] || Keychain.default.path
KEYCHAIN = Keychain.open keychain_path
SERVICE = 'linode-api'

def load_from_keychain
  entry = KEYCHAIN.generic_passwords.where(service: SERVICE).first
  fail(KeyError, 'Keychain item not found') unless entry
  entry.password
end

def save_to_keychain(key)
  KEYCHAIN.generic_passwords.create(service: SERVICE, password: key)
end

def load_from_prompt
  prompt = HighLine.new(STDIN, STDERR)
  username = prompt.ask('Linode Manager Username: ')
  password = prompt.ask('Linode Manager Password: ') { |q| q.echo = '*' }
  twofactor = prompt.ask('Linode Manager 2FA token: ')
  api = LinodeAPI::Raw.new(
    username: username,
    password: password,
    token: twofactor)
  api.apikey
end

begin
  key = load_from_keychain
rescue KeyError
  key = load_from_prompt
  save_to_keychain(key)
end

fail('Failed to load credentials') unless key
puts key
