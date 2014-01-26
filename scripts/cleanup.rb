##
# Remove extra users and files

require 'FileUtils'

CONFIG['cleanup']['users'].each do |user|
  `arch-chroot #{CONFIG['build_dir']} userdel #{user}`
end

CONFIG['cleanup']['paths'].each do |path|
  FileUtils.rm_rf "#{CONFIG['build_dir']}/#{path}"
end
