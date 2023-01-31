
class NxDrop

    # NxDrop::directory()
    def self.directory()
        "#{Config::pathToDataCenter()}/NxDrops"
    end

    # NxDrop::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(NxDrop::directory()).select{|filepath| filepath[-5, 5] == ".json" }
    end

    # NxDrop::filepathsForUUID(uuid)
    def self.filepathsForUUID(uuid)
        NxDrop::filepaths()
            .select{|filepath|
                (lambda{
                    item = JSON.parse(IO.read(filepath))
                    return false if item.nil?
                    item["uuid"] == uuid
                }).call()
            }
    end

    # NxDrop::filepathOrNull(uuid)
    def self.filepathOrNull(uuid)
        filepaths = NxDrop::filepathsForUUID(uuid)
        return nil if filepaths.size == 0
        return filepaths.first if filepaths.size == 1
        filepath = filepaths.first
        filepaths.drop(1).each{|fp| FileUtils.rm(fp) }
        filepath
    end

    # NxDrop::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filepath = NxDrop::filepathOrNull(uuid)
        return nil if filepath.nil?
        JSON.parse(IO.read(filepath))
    end

    # NxDrop::commit(item)
    def self.commit(item)
        filepaths = NxDrop::filepathsForUUID(item["uuid"])
        filepath = "#{NxDrop::directory()}/#{(1000*Time.new.to_f).to_i.to_s}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        filepaths.each{|fp| FileUtils.rm(fp) }
    end

    # NxDrop::issue()
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
            "runStartUnixtime" => nil
        }
        puts JSON.pretty_generate(item)
        NxDrop::commit(item)
    end

    # NxDrop::drops()
    def self.drops()
        NxDrop::filepaths().map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxDrop::toString(item)
    def self.toString(item)
        namex = item["tcName"] ? " (tc: #{item["tcName"]})" : ""
        runningx = item["runStartUnixtime"] ? " (running for #{((Time.new.to_i - item["runStartUnixtime"]).to_f/3600).round(2)} hours)" : ""
        "(drop) #{item["description"]}#{namex}#{runningx}"
    end

    # NxDrop::start(item)
    def self.start(item)
        item = NxDrop::getItemByUUIDOrNull(item["uuid"])
        return if item.nil?
        return if item["runStartUnixtime"] # already running
        item["runStartUnixtime"] = Time.new.to_i
        puts JSON.pretty_generate(item)
        NxDrop::commit(item)
    end

    # NxDrop::stop(item)
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
        NxDrop::commit(item)
    end

    # NxDrop::destroy(uuid)
    def self.destroy(uuid)
        NxDrop::filepathsForUUID(uuid).each{|fp| FileUtils.rm(fp) }
    end
end