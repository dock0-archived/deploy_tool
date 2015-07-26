#!/usr/bin/env ruby

require 'keychain'

api_key = Keychain.open('/Volumes/akerl-vault/dock0.keychain')
api_key = api_key.generic_passwords.where(service: 'linode-api')
fail('Failed to load keychain') unless api_key.first
puts api_key.first.password
