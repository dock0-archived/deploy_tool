##
# Process template files using provided config

require 'erb'

@config['templates'].each do |path|
  full_path = "#{@config['paths']['mount']}/#{path}"
  template = File.read full_path
  parsed = ERB.new(template).result
  File.open(full_path, 'w') { |fh| fh.write parsed }
end
