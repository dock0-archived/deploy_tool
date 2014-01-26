##
# Remove extra users and files

require 'FileUtils'

@config['cleanup']['users'].each do |user|
  puts "Removing user: #{user}"
  run "arch-chroot #{@config['paths']['build']} userdel #{user}"
end

@config['cleanup']['paths'].each do |path|
  puts "Removing path: #{path}"
  FileUtils.rm_rf "#{@config['paths']['build']}/#{path}"
end
