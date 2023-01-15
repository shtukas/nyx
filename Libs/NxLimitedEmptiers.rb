# encoding: UTF-8

class NxLimitedEmptiers

    # --------------------------------------------------
    # IO

    # NxLimitedEmptiers::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/NxLimitedEmptier"
    end

    # NxLimitedEmptiers::filepath(uuid)
    def self.filepath(uuid)
        "#{NxLimitedEmptiers::repositoryFolderPath()}/#{uuid}.json"
    end

    # NxLimitedEmptiers::commit(object)
    def self.commit(object)
        FileSystemCheck::fsck_MikuTypedItem(object, true)
        filepath = NxLimitedEmptiers::filepath(object["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
    end

    # NxLimitedEmptiers::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{NxLimitedEmptiers::repositoryFolderPath()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxLimitedEmptiers::items()
    def self.items()
        LucilleCore::locationsAtFolder(NxLimitedEmptiers::repositoryFolderPath())
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath))}
    end

    # NxLimitedEmptiers::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxLimitedEmptiers::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxLimitedEmptiers::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours (empty to abort): ")
        return nil if hours.nil?
        hours = hours.to_f
        uuid  = CommonUtils::timeStringL22()
        item = {
            "uuid"         => uuid,
            "mikuType"     => "NxLimitedEmptier",
            "unixtime"     => Time.new.to_i,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "hours"        => hours,
            "lastDoneDate" => nil
        }
        NxLimitedEmptiers::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxLimitedEmptiers::toString(item)
    def self.toString(item)
        valueToday = Bank::valueAtDate(item["uuid"], CommonUtils::today(), NxBalls::itemUnrealisedRunTimeInSecondsOrNull(item))
        "(limited emptier) #{item["description"]} (value today: #{(valueToday.to_f/3600).round(2)} hours, of: #{item["hours"]})"
    end

    # NxLimitedEmptiers::listingItems()
    def self.listingItems()
        NxLimitedEmptiers::items()
            .select{|item|
                valueToday = Bank::valueAtDate(item["uuid"], CommonUtils::today(), NxBalls::itemUnrealisedRunTimeInSecondsOrNull(item))
                b1 = (valueToday.to_f/3600) < item["hours"]
                b2 = (item["lastDoneDate"].nil? or (item["lastDoneDate"] != CommonUtils::today()))
                !NxBalls::getNxBallForItemOrNull(item).nil? or (b1 and b2)
            }
    end

    # NxLimitedEmptiers::numbers(item)
    def self.numbers(item)
        valueToday = Bank::valueAtDate(item["uuid"], CommonUtils::today(), NxBalls::itemUnrealisedRunTimeInSecondsOrNull(item))
        {
            "shouldListing"         => valueToday < item["hours"]*3600,
            "missingHoursForToday"  => (item["hours"]*3600 - valueToday).to_f/3600
        }
    end

    # --------------------------------------------------
    # Operations

    # NxLimitedEmptiers::probe(item)
    def self.probe(item)
        loop {
            item = NxLimitedEmptiers::getOrNull(item["uuid"])
            puts NxLimitedEmptiers::toString(item).green
            actions = ["access", "update description", "set project", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxLimitedEmptiers::access(item)
            end
            if action == "update description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                item["description"] = description
                NxLimitedEmptiers::commit(item)
            end
            if action == "set project" then
                project = NxProjects::interactivelySelectNxProjectOrNull()
                next if project.nil?
                item["projectId"] = project["uuid"]
                NxLimitedEmptiers::commit(item)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of NxLimitedEmptier '#{NxLimitedEmptiers::toString(item)}' ? ") then
                    NxLimitedEmptiers::destroy(item["uuid"])
                    PolyActions::garbageCollectionAfterItemDeletion(item)
                    return
                end
            end
        }
    end
end
