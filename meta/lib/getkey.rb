#!/usr/bin/env ruby

require 'keychain'

keychain = ENV['DOCK0_KEYCHAIN'] || Keychain.default

api_key = Keychain.open keychain
api_key = api_key.generic_passwords.where(service: 'linode-api')
fail('Failed to load keychain') unless api_key.first
puts api_key.first.password
