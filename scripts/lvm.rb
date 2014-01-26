##
# Prepare LVM device

puts "Removing any old LVM on #{@config['lvm']['name']} or #{@config['lvm']['device']}"
`vgremove -f #{@config['lvm']['name']}`
`pvremove #{@config['lvm']['device']}`

puts "Creating new PV and VG"
`pvcreate #{@config['lvm']['device']}`
`vgcreate #{@config['lvm']['name']} #{@config['lvm']['device']}`

@config['lvm']['lvs'].each do |name, options|
  puts "Creating LV: #{name}"
  `lvcreate -L #{options['size']} -n #{name} #{@config['lvm']['name']}`
  `mkfs -t #{options['fs']} /dev/#{@config['lvm']['name']}/#{name}`
end
