##
# Prepare LVM device

name = @config['lvm']['name']
device = @config['lvm']['device']

puts "Removing any old LVM on #{name} or #{device}"
`vgremove -f #{name} 2>&1`
`pvremove -ff -y #{device} 2>&1`

puts 'Creating new PV and VG'
run "pvcreate #{device}"
run "vgcreate #{name} #{device}"

@config['lvm']['lvs'].each do |lv_name, options|
  puts "Creating LV: #{lv_name}"
  run "lvcreate -L #{options['size']} -n #{lv_name} #{name}"
  run "mkfs -t #{options['fs']} /dev/#{name}/#{lv_name}"
end
