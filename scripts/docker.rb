##
# Add template files for spawning Docker containers

require 'fileutils'
require 'erb'

return unless @config[:containers]

def load_template(name)
  file = File.join(TEMPLATE_DIR, "container_#{name}.erb")
  ERB.new(File.read(file), nil, '<>')
end

def load_envfile(container, suffix, &block)
  file = File.join ENVFILE_DIR, "#{container[:envfile]}.#{suffix}"
  return unless File.exist? file
  block.call(file)
end

def add_envfile(container)
  return unless container[:envfile]
  data = load_envfile(container, 'txt') { |x| File.read(x) }
  data ||= load_envfile(container, 'rb') { |x| `#{x}` }
  fail("No envfile found: #{container[:envfile]}") unless data
  target_file = File.join ENVFILE_TARGET_DIR, container[:service]
  FileUtils.mkdir_p ENVFILE_TARGET_DIR

  File.open(target_file, 'w', 0600) { |fh| fh << data }
end

BASE_DIR = @paths[:docker] || './docker'

TEMPLATE_DIR = File.join(BASE_DIR, 'templates')
TEMPLATES = Hash[%w(run finish).map { |x| [x, load_template(x)] }]

ENVFILE_DIR = File.join(BASE_DIR, 'envfiles')

TARGET_DIR = File.join(@paths[:build], 'templates')
SERVICE_TARGET_DIR = File.join(TARGET_DIR, 'etc', 's6', 'service')
ENVFILE_TARGET_DIR = File.join(TARGET_DIR, 'etc', 'docker')

@config[:containers].each do |container|
  container[:service] = container[:name].gsub('/', '_')
  dir = File.join SERVICE_TARGET_DIR, "container_#{container[:service]}"
  TEMPLATES.each do |file, template|
    script = "#{dir}/#{file}"
    FileUtils.mkdir_p dir
    File.open(script, 'w', 0755) { |fh| fh.write template.result(binding) }
  end
  add_envfile(container)
end
