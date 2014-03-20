##
# Roll the new kernel

require 'fileutils'

version = @config['kernel']['version']
revision = @config['kernel']['revision']

puts "Rolling the kernel: #{version}_#{revision}"
location = run "roller.py \
  -s \
  -k #{version} \
  -c #{version} \
  -r #{revision} \
  -b #{@config['kernel']['tmpdir']} \
  -d #{@config['kernel']['configs']}
"

sleep 3
FileUtils.mkdir_p "#{@config['paths']['mount']}/boot/grub"
FileUtils.cp location.chomp, "#{@config['paths']['mount']}/boot/vmlinuz"

puts 'Generating the initrd'
initcpio_path = @config['kernel']['initcpio_helpers'] + '/.'
FileUtils.cp_r initcpio_path, '/usr/lib/initcpio'
FileUtils.mkdir_p "/lib/modules/#{version}_#{revision}"
run "mkinitcpio \
  -c /dev/null \
  -A #{@config['kernel']['modules']} \
  -g #{@config['paths']['mount']}/boot/initrd.img \
  -k #{version}_#{revision}
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
