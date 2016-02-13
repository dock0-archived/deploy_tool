#!/usr/bin/env ruby

require 'keylime'
require 'linodeapi'
require 'userinput'

QUIET = ARGV.first
CREDENTIAL = Keylime.new(server: 'https://api.linode.com', account: 'dock0')

def prompt(item, secret = false)
  UserInput.new(
    message: "Linode Manager #{item}",
    secret: secret,
    fd: STDERR
  ).ask
end

def load_apikey
  username = prompt('Username')
  password = prompt('Password', true)
  twofactor = prompt('2FA Token')
  LinodeAPI::Raw.new(
    username: username,
    password: password,
    token: twofactor
  ).apikey
end

def load_creds
  CREDENTIAL.set(load_apikey)
end

key = CREDENTIAL.get || load_creds
puts key.password unless QUIET
