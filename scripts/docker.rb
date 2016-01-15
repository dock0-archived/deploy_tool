##
# Add template files for spawning Docker containers

require 'fileutils'
require 'erb'

return unless @config[:containers]

TEMPLATE_DIR = @paths[:assets] || './assets'
TEMPLATE_FILE = File.join(TEMPLATE_DIR, 'container_init.erb')
TEMPLATE = ERB.new(File.read(TEMPLATE_FILE), nil, '<>')

@config[:containers].each do |container|
  service = container[:name].gsub('/', '_')
  dir = "#{@paths[:build]}/templates/etc/s6/services/#{service}"
  script = "#{dir}/run"

  FileUtils.mkdir_p dir
  File.open(script, 'w') { |fh| fh.write TEMPLATE.result(binding) }
end
