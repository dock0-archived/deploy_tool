##
# Prepare LVM device

`vgremove -f #{@config['lvm']['name']}`
`pvremove #{@config['lvm']['device']}`
`pvcreate #{@config['lvm']['device']}`
`vgcreate #{@config['lvm']['name']} #{@config['lvm']['device']}`

@config['lvm']['lvs'].each do |name, options|
  `lvcreate -L #{options['size']} -n #{name} #{@config['lvm']['name']}`
  `mkfs -t #{options['fs']} /dev/#{@config['lvm']['name']}/#{name}`
end
