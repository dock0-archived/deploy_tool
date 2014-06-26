##
# Configure the root user's environment

require 'fileutils'

# Disable password authentication
shadow_file = File.readlines '/etc/shadow'
shadow_file.first.gsub! 'root::', 'root:x:'
File.open('/etc/shadow', 'w') { |fh| shadow_file.each { |line| fh << line } }

# Set timezone
FileUtils.ln_s '/usr/share/zoneinfo/US/Eastern', '/etc/localtime'

# Generate locales
system 'locale-gen'

# Set root user to use zsh
system 'usermod -s /usr/local/bin/zsh'
