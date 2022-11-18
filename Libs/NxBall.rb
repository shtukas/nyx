
class NxBall

    # NxBall::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/NxBall"
        LucilleCore::locationsAtFolder(folderpath)
                .select{|filepath| filepath[-5, 5] == ".json" }
                .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxBall::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxBall/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxBall::commit(item)
    def self.commit(item)
        filepath = "#{Config::pathToDataCenter()}/NxBall/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxBall::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxBall/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxBall::interactivelyIssueNewNxBallOrNothing()
    def self.interactivelyIssueNewNxBallOrNothing()
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return if cx22.nil?
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxBall",
            "unixtime" => Time.new.to_f,
            "announce" => cx22["description"],
            "cx22"     => cx22["uuid"]
        }
        NxBall::commit(item)
        item
    end

    # NxBall::commitTime(item)
    def self.commitTime(item)
        timespan = Time.new.to_i - item["unixtime"]
        puts "Adding #{(timespan.to_f/3600).round(2)} hours to #{item["announce"]}"
        Bank::put(item["cx22"], timespan)
    end

    # NxBall::commitTimeAndDestroy(item)
    def self.commitTimeAndDestroy(item)
        NxBall::commitTime(item)
        NxBall::destroy(item["uuid"])
    end

    # NxBall::access(item)
    def self.access(item)
        if LucilleCore::askQuestionAnswerAsBoolean("stop NxBall '#{item["announce"]}' ? ") then
            NxBall::commitTime(item)
            NxBall::destroy(item["uuid"])
        end
    end
end