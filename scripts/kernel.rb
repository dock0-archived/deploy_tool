##
# Roll the new kernel

require 'fileutils'
require 'open-uri'

version = @config['kernel']['version']
url = "https://github.com/akerl/kernels/releases/download/#{version}/vmlinuz"

puts "Downloading the kernel: #{version}"
FileUtils.mkdir_p "#{@config['paths']['mount']}/boot/grub"
File.open("#{@config['paths']['mount']}/boot/vmlinuz", 'wb') do |fh|
  open(url, 'rb') { |request| fh.write request.read }
end

puts 'Generating the initrd'
initcpio_path = @config['kernel']['initcpio_helpers'] + '/.'
FileUtils.cp_r initcpio_path, '/usr/lib/initcpio'
FileUtils.mkdir_p "/lib/modules/#{version}"
run "mkinitcpio \
  -c /dev/null \
  -A #{@config['kernel']['modules']} \
  -g #{@config['paths']['mount']}/boot/initrd.img \
  -k #{version}
"

puts 'Creating the grub config'

kernel_options = @config['kernel']['options'].reduce('') do |a, (k, v)|
  a + "#{k}=#{v} "
end
grub_config = "timeout 10
default 0

title dock0
root (hd0)
kernel /boot/vmlinuz #{kernel_options}
initrd /boot/initrd.img
"

File.open("#{@config['paths']['mount']}/boot/grub/menu.lst", 'w') do |fh|
  fh.write grub_config
end
