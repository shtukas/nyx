
class NxTops

    # NxTops::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTop/#{uuid}.json"
    end

    # NxTops::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTop")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxTops::commit(item)
    def self.commit(item)
        filepath = NxTops::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxTops::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxTops::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxTops::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTops::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxTops::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTop",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description
        }
        NxTops::commit(item)
        item
    end
    
    # NxTops::listingItems()
    def self.listingItems()
        NxTops::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end