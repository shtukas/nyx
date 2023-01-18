
class NsTopLines

    # NsTopLines::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NsTopLine/#{uuid}.json"
    end

    # NsTopLines::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NsTopLine")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NsTopLines::commit(item)
    def self.commit(item)
        filepath = NsTopLines::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NsTopLines::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NsTopLines::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NsTopLines::destroy(uuid)
    def self.destroy(uuid)
        filepath = NsTopLines::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NsTopLines::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        return nil if line == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"      => uuid,
            "mikuType"  => "NsTopLine",
            "unixtime"  => Time.new.to_i,
            "line"      => line
        }
        NsTopLines::commit(item)
        item
    end
    
    # NsTopLines::listingItems()
    def self.listingItems()
        NsTopLines::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end