##
# Prepare LVM device

`vgremove -f #{CONFIG['vg_name']}`
`pvremove #{CONFIG['lvm_path']}`
`pvcreate #{CONFIG['lvm_path']}`
`vgcreate #{CONFIG['vg_name']} #{CONFIG['lvm_path']}`

CONFIG['lvs'].each do |name, options|
  `lvcreate -L #{options['size']} -n #{name} #{CONFIG['vg_name'}`
  `mkfs -t #{options['fs']} /dev/#{CONFIG['vg_name'}/#{name}`
end
