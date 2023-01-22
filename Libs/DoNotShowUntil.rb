# encoding: UTF-8

class DoNotShowUntilAgent

    def initialize()
        @mapping = {}
        Thread.new {
            loop {
                sleep 120
                loadFromDisk()
            }
        }
    end

    def filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/DoNotShowUntil2")
            .select{|filepath| filepath[-5, 5] == ".json" }
    end

    # filepathsForUuid(uuid) # filepaths for this uuid (possibly empty)
    def filepathsForUuid(uuid)
        filepaths()
            .select{|filepath|
                data = JSON.parse(IO.read(filepath))
                data["uuid"] == uuid
            }
    end

    def setUnixtime(uuid, unixtime)
        filepathsForUuid(uuid)
            .each{|filepath| FileUtils.rm(filepath)}

        data = {
            "uuid"     => uuid,
            "unixtime" => unixtime
        }
        contents = JSON.generate(data)
        filename = "#{Digest::SHA1.hexdigest(contents)}.json"
        filepath = "#{Config::pathToDataCenter()}/DoNotShowUntil2/#{filename}"
        File.open(filepath, "w") {|f| f.puts(contents) }

        @mapping[uuid] = unixtime
    end

    def loadFromDisk()
        filepaths().each{|filepath|
            data = JSON.parse(IO.read(filepath))
            if data["unixtime"] > Time.new.to_i then
                @mapping[data["uuid"]] = data["unixtime"]
            else
                FileUtils.rm(filepath)
            end
        }
    end

    def unixtimeOrNull(uuid)
        return @mapping[uuid] if @mapping[uuid]
        loadFromDisk()
        return @mapping[uuid] if @mapping[uuid]
        @mapping[uuid] = 0 # technically we should be returning null but we set 0 to avoid reloading from disk for the same uuid later
        0
    end
end

$DoNotShowUntilAgent = nil

class DoNotShowUntil

    # DoNotShowUntil::agent()
    def self.agent()
        if $DoNotShowUntilAgent.nil? then
            $DoNotShowUntilAgent = DoNotShowUntilAgent.new()
        end
        $DoNotShowUntilAgent
    end

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        DoNotShowUntil::agent().setUnixtime(uuid, unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        DoNotShowUntil::agent().unixtimeOrNull(uuid)
    end

    # DoNotShowUntil::getDateTimeOrNull(uuid)
    def self.getDateTimeOrNull(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return nil if unixtime.nil?
        return nil if Time.new.to_i >= unixtime.to_i
        Time.at(unixtime).utc.iso8601
    end

    # DoNotShowUntil::isVisible(uuid)
    def self.isVisible(uuid)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(uuid)
        return true if unixtime.nil?
        Time.new.to_i >= unixtime.to_i
    end
end
