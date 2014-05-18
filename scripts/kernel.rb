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

puts 'Creating the grub2 config'
kernel_options = @config['kernel']['options'].reduce('') do |a, (k, v)|
  a + "#{k}=#{v} "
end
grub_config = "set default='0'
set timeout='10'

menuentry 'dock0' --class archlinux --class gnu-linux --class gnu --class os {
  insmod ext2
  set root='(hd0)'
  linux /boot/vmlinuz #{kernel_options}
  initrd /boot/initrd.img
}
"
File.open("#{@config['paths']['mount']}/boot/grub/grub.cfg", 'w') do |fh|
  fh.write grub_config
end

puts 'Creating the grub-xen config'
File.open("#{@config['kernel']['tmpdir']}/load.cf", 'w') do |fh|
  fh.write 'configfile (xen/xvda)/boot/grub/grub.cfg'
end
run "grub-mkimage \
  --prefix '(xen/xvda)/boot/grub' \
  -c #{@config['kernel']['tmpdir']}/load.cf \
  -O x86_64-xen \
  -o #{@config['paths']['mount']}/boot/shim \
  -d /usr/lib/grub/x86_64-efi \
  /usr/lib/grub/x86_64-efi/*.mod
"
shim_config = 'default 1
timeout 10

title shim
root (hd0)
kernel /boot/shim
boot
'
File.open("#{@config['paths']['mount']}/boot/grub/menu.lst", 'w') do |fh|
  fh.write shim_config
end

FileUtils.remove_dir @config['kernel']['tmpdir']
