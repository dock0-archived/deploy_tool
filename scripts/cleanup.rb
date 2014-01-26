##
# Remove extra users and files

require 'FileUtils'

@config['cleanup']['users'].each do |user|
  puts "Removing user: #{user}"
  `arch-chroot #{@config['paths']['mount']} userdel #{user}`
end

@config['cleanup']['paths'].each do |path|
  puts "Removing path: #{path}"
  FileUtils.rm_rf "#{@config['paths']['mount']}/#{path}"
end
