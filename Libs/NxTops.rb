
class NxTops

    # NxTops::directory()
    def self.directory()
        "#{Config::pathToDataCenter()}/NxTops"
    end

    # NxTops::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(NxTops::directory()).select{|filepath| filepath[-5, 5] == ".json" }
    end

    # NxTops::filepathsForUUID(uuid)
    def self.filepathsForUUID(uuid)
        NxTops::filepaths()
            .select{|filepath|
                (lambda{
                    item = JSON.parse(IO.read(filepath))
                    return false if item.nil?
                    item["uuid"] == uuid
                }).call()
            }
    end

    # NxTops::filepathOrNull(uuid)
    def self.filepathOrNull(uuid)
        filepaths = NxTops::filepathsForUUID(uuid)
        return nil if filepaths.size == 0
        return filepaths.first if filepaths.size == 1
        filepath = filepaths.first
        filepaths.top(1).each{|fp| FileUtils.rm(fp) }
        filepath
    end

    # NxTops::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filepath = NxTops::filepathOrNull(uuid)
        return nil if filepath.nil?
        JSON.parse(IO.read(filepath))
    end

    # NxTops::commit(item)
    def self.commit(item)
        filepaths = NxTops::filepathsForUUID(item["uuid"])
        filepath = "#{NxTops::directory()}/#{(1000*Time.new.to_f).to_i.to_s}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        filepaths.each{|fp| FileUtils.rm(fp) }
    end

    # NxTops::issue()
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
        NxTops::commit(item)
    end

    # NxTops::tops()
    def self.tops()
        NxTops::filepaths().map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxTops::toString(item)
    def self.toString(item)
        namex = item["tcName"] ? " (tc: #{item["tcName"]})" : ""
        runningx = item["runStartUnixtime"] ? " (running for #{((Time.new.to_i - item["runStartUnixtime"]).to_f/3600).round(2)} hours)" : ""
        "(top) #{item["description"]}#{namex}#{runningx}"
    end

    # NxTops::destroy(uuid)
    def self.destroy(uuid)
        NxTops::filepathsForUUID(uuid).each{|fp| FileUtils.rm(fp) }
    end
end