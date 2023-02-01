
class NxDrops

    # NxDrops::directory()
    def self.directory()
        "#{Config::pathToDataCenter()}/NxDrops"
    end

    # NxDrops::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(NxDrops::directory()).select{|filepath| filepath[-5, 5] == ".json" }
    end

    # NxDrops::filepathsForUUID(uuid)
    def self.filepathsForUUID(uuid)
        NxDrops::filepaths()
            .select{|filepath|
                (lambda{
                    item = JSON.parse(IO.read(filepath))
                    return false if item.nil?
                    item["uuid"] == uuid
                }).call()
            }
    end

    # NxDrops::filepathOrNull(uuid)
    def self.filepathOrNull(uuid)
        filepaths = NxDrops::filepathsForUUID(uuid)
        return nil if filepaths.size == 0
        return filepaths.first if filepaths.size == 1
        filepath = filepaths.first
        filepaths.drop(1).each{|fp| FileUtils.rm(fp) }
        filepath
    end

    # NxDrops::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filepath = NxDrops::filepathOrNull(uuid)
        return nil if filepath.nil?
        JSON.parse(IO.read(filepath))
    end

    # NxDrops::commit(item)
    def self.commit(item)
        filepaths = NxDrops::filepathsForUUID(item["uuid"])
        filepath = "#{NxDrops::directory()}/#{(1000*Time.new.to_f).to_i.to_s}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        filepaths.each{|fp| FileUtils.rm(fp) }
    end

    # NxDrops::issue()
    def self.issue()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        uuid  = SecureRandom.uuid
        tc = NxTimeCommitments::interactivelySelectOneOrNull()
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxDrop",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "tcId"             => tc ? tc["uuid"] : nil,
            "tcName"           => tc ? tc["description"] : nil,
            "runStartUnixtime" => nil,
            "field13"       => Database2Engine::trajectory(Time.new.to_f, 48)
        }
        puts JSON.pretty_generate(item)
        NxDrops::commit(item)
    end

    # NxDrops::drops()
    def self.drops()
        NxDrops::filepaths().map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxDrops::toString(item)
    def self.toString(item)
        namex = item["tcName"] ? " (tc: #{item["tcName"]})" : ""
        runningx = item["runStartUnixtime"] ? " (running for #{((Time.new.to_i - item["runStartUnixtime"]).to_f/3600).round(2)} hours)" : ""
        "(drop) #{item["description"]}#{namex}#{runningx}"
    end

    # NxDrops::start(item)
    def self.start(item)
        item = NxDrops::getItemByUUIDOrNull(item["uuid"])
        return if item.nil?
        return if item["runStartUnixtime"] # already running
        item["runStartUnixtime"] = Time.new.to_i
        puts JSON.pretty_generate(item)
        NxDrops::commit(item)
    end

    # NxDrops::stop(item)
    def self.stop(item)
        return if item["runStartUnixtime"].nil?
        if item["tcId"] then
            timespanInHours = (Time.new.to_i - item["runStartUnixtime"]).to_f/3600
            tdrop = {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "NxTimeCapsule",
                "unixtime"     => Time.new.to_i,
                "datetime"     => Time.new.utc.iso8601,
                "description"  => "automatically generated using: #{item["description"]}",
                "field1"       => -timespanInHours,
                "field2"       => nil,
                "field4"       => item["tcId"]
            }
            puts JSON.pretty_generate(tdrop)
            TodoDatabase2::commitItem(tdrop)
        end
        item["runStartUnixtime"] = nil?
        puts JSON.pretty_generate(item)
        NxDrops::commit(item)
    end

    # NxDrops::destroy(uuid)
    def self.destroy(uuid)
        NxDrops::filepathsForUUID(uuid).each{|fp| FileUtils.rm(fp) }
    end
end