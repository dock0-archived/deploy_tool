##
# Add template files for spawning Docker containers

require 'fileutils'
require 'erb'

return unless @config[:containers]

def load_template(name)
  file = File.join(TEMPLATE_DIR, "container_#{name}.erb")
  ERB.new(File.read(file), nil, '<>')
end

TEMPLATE_DIR = @paths[:assets] || './assets'
TEMPLATES = Hash[%w(run finish).map { |x| [x, load_template(x)] }]

@config[:containers].each do |container|
  service = container[:name].gsub('/', '_')
  dir = "#{@paths[:build]}/templates/etc/s6/service/#{service}"
  TEMPLATES.each do |file, template|
    script = "#{dir}/#{file}"
    FileUtils.mkdir_p dir
    File.open(script, 'w', 0755) { |fh| fh.write template.result(binding) }
  end
end
