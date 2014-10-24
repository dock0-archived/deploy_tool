##
# Flip bits as appropriate if we're in debug mode

return unless File.exist? '/tmp/debug_mode'

puts 'Debug mode activated'

# Copy root password for maker to new root
lines = [open('/etc/shadow').readlines.first]
File.open(@config['paths']['build'] + '/etc/shadow') do |fh|
  fh.readlines[1..-1].each { |line| lines << line }
end
File.open(@config['paths']['build'] + '/etc/shadow', 'w') do |fh|
  lines.each { |line| fh.write line }
end
