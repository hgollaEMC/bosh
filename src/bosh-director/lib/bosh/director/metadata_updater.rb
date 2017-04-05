module Bosh::Director
  class MetadataUpdater
    include CloudFactoryHelper

    def self.build
      new({'director' => Config.name}, Config.logger)
    end

    def initialize(director_metadata, logger)
      @director_metadata = director_metadata
      @logger = logger
    end

    def update_vm_metadata(instance, metadata, factory = cloud_factory)
      cloud = factory.for_availability_zone!(instance.availability_zone)

      if cloud.respond_to?(:set_vm_metadata)
        metadata = metadata.merge(@director_metadata)
        metadata['deployment'] = instance.deployment.name
        metadata['id'] = instance.uuid
        metadata['job'] = instance.job
        metadata['index'] = instance.index.to_s
        metadata['name'] = "#{instance.job}/#{instance.uuid}"
        metadata['created_at'] = Time.new.getutc.strftime('%Y-%m-%dT%H:%M:%SZ')

        cloud.set_vm_metadata(instance.vm_cid, metadata)
      end
    rescue Bosh::Clouds::NotImplemented => e
      @logger.debug(e.inspect)
    end

    def update_disk_metadata(cloud, disk, metadata)
      if cloud.respond_to?(:set_disk_metadata)
        metadata = metadata.merge(@director_metadata)
        metadata['deployment'] = disk.instance.deployment.name
        metadata['instance_id'] = disk.instance.uuid
        metadata['job'] = disk.instance.job
        metadata['instance_index'] = disk.instance.index.to_s
        metadata['instance_name'] = "#{disk.instance.job}/#{disk.instance.uuid}"
        metadata['attached_at'] = Time.new.getutc.strftime('%Y-%m-%dT%H:%M:%SZ')

        cloud.set_disk_metadata(disk.disk_cid, metadata)
      end
    rescue Bosh::Clouds::NotImplemented => e
       @logger.debug(e.inspect)
    end
  end
end
