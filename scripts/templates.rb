##
# Process template files using provided config

require 'erb'
require 'fileutils'

templates = Dir.chdir(@config['paths']['templates']) do
  Dir.glob('**/*').select { |x| File.file? x }
end

templates.each do |path|
  puts "Handling template: #{path}"
  template = File.read "#{@config['paths']['templates']}/#{path}"
  parsed = ERB.new(template, nil, '<>').result(binding)

  target_path = "#{@config['paths']['mount']}/config/templates/#{path}"
  FileUtils.mkdir_p File.dirname(target_path)
  File.open(target_path, 'w') { |fh| fh.write parsed }

  File.symlink "/run/dock0/bootmnt/configs/templates/#{path}", "/#{path}"
end
