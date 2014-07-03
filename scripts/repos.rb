##
# Configure system info repositories

Repo = Struct.new(:source, :dest, :command)

repos = [
  Repo.new(
    'git://github.com/akerl/scripts.git',
    '/opt/scripts',
    '/opt/scripts/script_sync /opt/scripts'
  ),
  Repo.new(
    'git://github.com/akerl/keys.git',
    '/opt/keys',
    '/opt/scripts/key_sync /opt/keys/strong /root/.ssh/authorized_keys quiet'
  )
]

base = @config['paths']['build']

repos.each do |repo|
  run "git clone #{repo.source} #{base}#{repo.dest}"
  run_chroot repo.command
end
