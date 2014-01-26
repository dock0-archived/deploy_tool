##
# Roll the new kernel

require 'FileUtils'

location = `roller.py \
  -s \
  -k #{CONFIG['kernel']['version']} \
  -c #{CONFIG['kernel']['version']} \
  -r #{CONFIG['kernel']['revision']} \
  -b #{CONFIG['config_path']}/tmp \
  -d #{CONFIG['config_path']}/kernels
`

FileUtils.mkdir_p "#{CONFIG['mount_path']}/boot/grub"
FileUtils.cp location, "#{CONFIG['mount_path']}/boot/vmlinuz"

FileUtils.mkdir_p "/lib/modules/#{CONFIG['kernel']['version']}_#{CONFIG['kernel']['revision']}"
`mkinitcpio \
  -c /dev/null \
  -A 'base,udev,lvm2,archiso' \
  -g #{CONFIG['mount_path']}/boot/initrd.img \
  -k #{CONFIG['kernel']['version']}_#{CONFIG['kernel']['revision']}
`

kernel_options = CONFIG['kernel']['options'].reduce('') { |a, (k, v)| a + "#{k}=#{v} " }

grub_config = "timeout 10
default 0

title dock0
root (hd0)
kernel /boot/vmlinuz #{kernel_options}
initrd /boot/initrd.img"

File.open("#{CONFIG['mount_path']}/boot/grub/menu.lst", 'w') do |fh|
  fh.write grub_config
end
