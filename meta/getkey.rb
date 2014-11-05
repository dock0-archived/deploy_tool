#!/usr/bin/env ruby

require 'keychain'

api_key = Keychain.open('/Volumes/akerl-vault/dock0.keychain')
api_key = api_key.generic_passwords.where(service: 'linode-api')
puts api_key.first.password
