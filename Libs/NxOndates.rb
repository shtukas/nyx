# encoding: UTF-8

class NxOndates

    # NxOndates::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxOndate/#{uuid}.json"
    end

    # NxOndates::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxOndate")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxOndates::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxOndates::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxOndates::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxOndates::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxOndates::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxOndates::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => datetime,
            "description" => description,
            "nx113"       => nx113,
        }
        NxOndates::commit(item)
        item
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("today (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        NxOndates::commit(item)
        item
    end

    # NxOndates::viennaUrlForToday(url)
    def self.viennaUrlForToday(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::url(url)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        NxOndates::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(ondate: #{item["datetime"][0, 10]}) #{item["description"]}#{nx113str}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        NxOndates::items().select{|item| item["datetime"][0, 10] <= Time.new.to_s[0, 10] }
    end

    # --------------------------------------------------
    # Operations

    # NxOndates::access(item)
    def self.access(item)
        puts NxOndates::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxOndates::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxOndates::getOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxOndates::getOrNull(item["uuid"])
    end

    # NxOndates::probe(item)
    def self.probe(item)
        loop {
            item = NxOndates::getOrNull(item["uuid"])
            actions = ["access", "redate", "transmute", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxOndates::access(item)
                next
            end
            if action == "transmute" then
                Transmutations::transmute2(item)
                return
            end
            if action == "redate" then
                item["datetime"] = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
                NxOndates::commit(item)
                next
            end
            if action == "destroy" then
                NxOndates::destroy(item["uuid"])
                return
            end
        }
    end
end
