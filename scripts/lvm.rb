##
# Prepare LVM device

puts "Removing any old LVM on #{@config['lvm']['name']} or #{@config['lvm']['device']}"
`vgremove -f #{@config['lvm']['name']} 2>&1`
`pvremove -ff -y #{@config['lvm']['device']} 2>&1`

puts "Creating new PV and VG"
run "pvcreate #{@config['lvm']['device']}"
run "vgcreate #{@config['lvm']['name']} #{@config['lvm']['device']}"

@config['lvm']['lvs'].each do |name, options|
  puts "Creating LV: #{name}"
  run "lvcreate -L #{options['size']} -n #{name} #{@config['lvm']['name']}"
  run "mkfs -t #{options['fs']} /dev/#{@config['lvm']['name']}/#{name}"
end
