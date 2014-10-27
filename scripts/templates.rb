##
# Process template files using provided config

require 'erb'
require 'fileutils'

templates = Dir.glob("#{@config['paths']['templates']}**/*").select do |x|
  File.file? x 
end

templates.each do |path|
  puts "Handling template: #{path}"
  template = File.read path
  target_path = "#{@config['paths']['mount']}/config/templates/#{path}"
  FileUtils.mkdir_p File.dirname(target_path)
  parsed = ERB.new(File.read path, nil, '<>').result(binding)
  File.open(target_path, 'w') { |fh| fh.write parsed }
end
