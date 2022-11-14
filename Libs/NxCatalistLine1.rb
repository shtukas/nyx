class NxCatalistLine1

    # NxCatalistLine1::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        return nil if line == ""
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxCatalistLine1",
            "unixtime" => Time.new.to_f,
            "line"     => line,
        }
        filepath = "#{Config::pathToDataCenter()}/NxCatalistLine1/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        item
    end

    # NxCatalistLine1::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/NxCatalistLine1"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxCatalistLine1::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxCatalistLine1/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxCatalistLine1::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxCatalistLine1/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Data

    # NxCatalistLine1::toString(item)
    def self.toString(item)
        "(line) #{item["line"]}#{Cx22::contributionStringWithPrefixForCatalystItemOrEmptyString(item).green}"
    end
end
