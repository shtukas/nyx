# encoding: UTF-8

class NxLines

    # NxLines::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, SecureRandom.hex, false)
        filepath = "#{Config::pathToDataCenter()}/NxLine/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxLines::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxLine/#{item["uuid"]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxLines::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxLine",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "line"        => line
        }
        NxLines::commit(item)
        item
    end

    # NxLines::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/NxLine"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxLines::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxLine/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxLines::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxLine/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

end
