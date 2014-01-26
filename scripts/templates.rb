##
# Process template files using provided config

@config['templates'].each do |path|
  puts "Handling template: #{path}"
  full_path = "#{@config['paths']['mount']}/#{path}"
  template = File.read full_path
  parsed = ERB.new(template).result
  File.open(full_path, 'w') { |fh| fh.write parsed }
end
