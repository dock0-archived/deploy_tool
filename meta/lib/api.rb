require 'linodeapi'

module API
  class << self
    def new(*args)
      self::Wrapper.new(*args)
    end
  end

  class Wrapper
    def initialize(hostname)
      @hostname = hostname
    end

    def jobs_running?
      jobs = api.linode.job.list(linodeid: linodeid)
      jobs.select { |job| job[:host_finish_dt] == '' }.length > 0
    end

    def wait_for_jobs
      while jobs_running?
        print '.'
        sleep 5
      end
      puts
    end

    def delete_all!
      puts 'Shutting down and removing existing data'
      api.linode.shutdown(linodeid: linodeid)
      configs, disks = existing
      configs.each do |c|
        api.linode.config.delete(linodeid: linodeid, configid: c[:configid])
      end
      disks.each do |d|
        api.linode.disk.delete(linodeid: linodeid, diskid: d[:diskid])
      end
    end

    def create_disk(params)
      res = api.linode.disk.create params.merge(linodeid: linodeid)
      res[:diskid]
    end

    def create_from_stackscript(params)
      res = api.linode.disk.createfromstackscript(
        params.merge(linodeid: linodeid)
      )
      res[:diskid]
    end

    def create_from_image(params)
      res = api.linode.disk.createfromimage(
        params.merge(linodeid: linodeid)
      )
      res[:diskid]
    end

    def create_config(params)
      res = api.linode.config.create params.merge(linodeid: linodeid)
      res[:configid]
    end

    def update_config(params)
      res = api.linode.config.update params.merge(linodeid: linodeid)
    end

    def get_image(label)
      api.image.list.find { |l| l[:label] == label }
    end

    def delete_image_by_label(label)
      image = get_image(label)
      api.image.delete(imageid: image.imageid) if image
    end

    def imagize(params)
      res = api.linode.disk.imagize params.merge(linodeid: linodeid)
      res[:imageid]
    end

    def boot(configid)
      api.linode.boot(linodeid: linodeid, configid: configid)
      sleep 2
      wait_for_jobs
    end

    def shutdown
      api.linode.shutdown(linodeid: linodeid)
      sleep 2
      wait_for_jobs
    end

    def api
      return @api if @api
      api_key = `./meta/lib/getkey.rb`
      fail('API key request failed') if api_key.empty?
      @api = LinodeAPI::Raw.new(apikey: api_key)
    end

    def linodeid
      return @linodeid if @linodeid
      linode = api.linode.list.find { |l| l[:label] == @hostname }
      @linodeid = linode.linodeid || fail('Linode not found')
    end

    def existing
      [
        api.linode.config.list(linodeid: linodeid),
        api.linode.disk.list(linodeid: linodeid)
      ]
    end
  end
end
