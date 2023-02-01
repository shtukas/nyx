
class NxTop

    # NxTop::directory()
    def self.directory()
        "#{Config::pathToDataCenter()}/NxTops"
    end

    # NxTop::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(NxTop::directory()).select{|filepath| filepath[-5, 5] == ".json" }
    end

    # NxTop::filepathsForUUID(uuid)
    def self.filepathsForUUID(uuid)
        NxTop::filepaths()
            .select{|filepath|
                (lambda{
                    item = JSON.parse(IO.read(filepath))
                    return false if item.nil?
                    item["uuid"] == uuid
                }).call()
            }
    end

    # NxTop::filepathOrNull(uuid)
    def self.filepathOrNull(uuid)
        filepaths = NxTop::filepathsForUUID(uuid)
        return nil if filepaths.size == 0
        return filepaths.first if filepaths.size == 1
        filepath = filepaths.first
        filepaths.top(1).each{|fp| FileUtils.rm(fp) }
        filepath
    end

    # NxTop::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filepath = NxTop::filepathOrNull(uuid)
        return nil if filepath.nil?
        JSON.parse(IO.read(filepath))
    end

    # NxTop::commit(item)
    def self.commit(item)
        filepaths = NxTop::filepathsForUUID(item["uuid"])
        filepath = "#{NxTop::directory()}/#{(1000*Time.new.to_f).to_i.to_s}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        filepaths.each{|fp| FileUtils.rm(fp) }
    end

    # NxTop::issue()
    def self.issue()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        uuid  = SecureRandom.uuid
        tc = NxTimeCommitments::interactivelySelectOneOrNull()
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxTop",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "tcId"             => tc ? tc["uuid"] : nil,
            "tcName"           => tc ? tc["description"] : nil,
            "runStartUnixtime" => nil
        }
        puts JSON.pretty_generate(item)
        NxTop::commit(item)
    end

    # NxTop::tops()
    def self.tops()
        NxTop::filepaths().map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxTop::toString(item)
    def self.toString(item)
        namex = item["tcName"] ? " (tc: #{item["tcName"]})" : ""
        runningx = item["runStartUnixtime"] ? " (running for #{((Time.new.to_i - item["runStartUnixtime"]).to_f/3600).round(2)} hours)" : ""
        "(top) #{item["description"]}#{namex}#{runningx}"
    end

    # NxTop::start(item)
    def self.start(item)
        item = NxTop::getItemByUUIDOrNull(item["uuid"])
        return if item.nil?
        return if item["runStartUnixtime"] # already running
        item["runStartUnixtime"] = Time.new.to_i
        puts JSON.pretty_generate(item)
        NxTop::commit(item)
    end

    # NxTop::stop(item)
    def self.stop(item)
        return if item["runStartUnixtime"].nil?
        if item["tcId"] then
            timespanInHours = (Time.new.to_i - item["runStartUnixtime"]).to_f/3600
            ttop = {
                "uuid"         => SecureRandom.uuid,
                "mikuType"     => "NxTimeCapsule",
                "unixtime"     => Time.new.to_i,
                "datetime"     => Time.new.utc.iso8601,
                "description"  => "automatically generated using: #{item["description"]}",
                "field1"       => -timespanInHours,
                "field2"       => nil,
                "field4"       => item["tcId"]
            }
            puts JSON.pretty_generate(ttop)
            TodoDatabase2::commitItem(ttop)
        end
        item["runStartUnixtime"] = nil?
        puts JSON.pretty_generate(item)
        NxTop::commit(item)
    end

    # NxTop::destroy(uuid)
    def self.destroy(uuid)
        NxTop::filepathsForUUID(uuid).each{|fp| FileUtils.rm(fp) }
    end
end