##
# Remove extra users and files

require 'fileutils'

@config['cleanup']['users'].each do |user|
  puts "Removing user: #{user}"
  run_chroot "userdel #{user}"
end

@config['cleanup']['paths'].each do |path|
  puts "Removing path: #{path}"
  FileUtils.rm_rf "#{@config['paths']['build']}/#{path}"
end

run_chroot 'pacman -Scc --noconfirm'
run_chroot 'find /usr/share/locale/ ' \
  '-maxdepth 1 -mindepth 1 -type d ! -name "en_US" ' \
  '-exec rm -r {} \;'
