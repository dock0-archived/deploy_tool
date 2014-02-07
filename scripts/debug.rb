##
# Flip bits as appropriate if we're in debug mode

return unless File.exists? '/tmp/debug_mode'

# Copy root password for maker to new root
lines = [
  open('/etc/shadow').readlines.first,
  *open(@config['paths']['build'] + '/etc/shadow').readlines[1..-1]
]
open(@config['paths']['build'] + '/etc/shadow', 'w') do |fh|
  lines.each { |line| fh.write line }
end
