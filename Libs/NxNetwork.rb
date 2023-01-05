# encoding: UTF-8

class NxNetwork

    # NxNetwork::link(uuid1, uuid2)
    def self.link(uuid1, uuid2)
        dir1 = "#{Config::pathToNyx()}/Network/#{uuid1}"
        if !File.exists?(dir1) then
            FileUtils::mkdir(dir1)
        end
        filepath1 = "#{dir1}/#{uuid2}.link"
        if !File.exists?(filepath1) then
            FileUtils.touch(filepath1)
        end

        dir2 = "#{Config::pathToNyx()}/Network/#{uuid2}"
        if !File.exists?(dir2) then
            FileUtils::mkdir(dir2)
        end
        filepath2 = "#{dir2}/#{uuid1}.link"
        if !File.exists?(filepath2) then
            FileUtils.touch(filepath2)
        end
    end

    # NxNetwork::unlink(uuid1, uuid2)
    def self.unlink(uuid1, uuid2)
        dir1 = "#{Config::pathToNyx()}/Network/#{uuid1}"
        filepath1 = "#{dir1}/#{uuid2}.link"
        if File.exists?(filepath1) then
            FileUtils.rm(filepath1)
        end

        dir2 = "#{Config::pathToNyx()}/Network/#{uuid2}"
        filepath2 = "#{dir2}/#{uuid1}.link"
        if File.exists?(filepath2) then
            FileUtils.rm(filepath2)
        end
    end

    # NxNetwork::linkedUUIDs(uuid)
    def self.linkedUUIDs(uuid)
        dir = "#{Config::pathToNyx()}/Network/#{uuid}"
        return [] if !File.exists?(dir)
        LucilleCore::locationsAtFolder(dir)
            .map{|filepath| File.basename(filepath).gsub(".link", "") }
    end
end