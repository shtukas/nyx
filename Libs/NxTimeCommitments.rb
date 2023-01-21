
class NxTimeCommitments

    # NxTimeCommitments::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTimeCommitment/#{uuid}.json"
    end

    # NxTimeCommitments::items()
    def self.items()
        items = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTimeCommitment")
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .map{|filepath| JSON.parse(IO.read(filepath)) }
        XCache::set("NxTimeCommitment-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E", items.map{|item| item["description"].size }.max)
        items
    end

    # NxTimeCommitments::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxTimeCommitments::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxTimeCommitments::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxTimeCommitments::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxTimeCommitments::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTimeCommitments::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # Makers

    # NxTimeCommitments::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxTimeCommitment",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39
        }
        FileSystemCheck::fsck_NxTimeCommitment(item, true)
        NxTimeCommitments::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxTimeCommitments::toString(item)
    def self.toString(item)
        "(project) #{item["description"]}"
    end

    # NxTimeCommitments::toStringWithDetails(item, shouldFormat)
    def self.toStringWithDetails(item, shouldFormat)
        descriptionPadding = 
            if shouldFormat then
                (XCache::getOrNull("NxTimeCommitment-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 0).to_i
            else
                0
            end

        timeload = NxTCTimeLoads::getTimeLoadInSeconds(item["uuid"]).to_f/3600
        dataStr = " (pending today: #{"%5.2f" % timeload})"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ", (do not show until: #{datetimeOpt})" : ""

        "(project) #{item["description"].ljust(descriptionPadding)} (#{Ax39::toStringFormatted(item["ax39"])})#{dataStr}#{dnsustr}"
    end

    # NxTimeCommitments::runningItems()
    def self.runningItems()
        NxTimeCommitments::items()
            .select{|project| NxBalls::getNxBallForItemOrNull(project) }
    end

    # NxTimeCommitments::firstNxTodoItemsForNxTimeCommitment(tcId)
    def self.firstNxTodoItemsForNxTimeCommitment(tcId)
        filepath = "#{Config::pathToDataCenter()}/NxTimeCommitment-to-FirstItems/#{tcId}.json"

        getDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            packet["uuids"]
                .map{|uuid| NxTodos::getOrNull(uuid) }
                .compact
        }

        getRecentDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            return nil if (Time.new.to_i - packet["unixtime"]) > 3600
            packet["uuids"]
                .map{|uuid| NxTodos::getOrNull(uuid) }
                .compact
        }

        issueNewFile = lambda {|filepath, tcId|
            #puts "> issuing new file for project: #{NxTimeCommitments::getOrNull(tcId)["description"]}"
            items = NxTodos::itemsForNxTimeCommitment(tcId)
                        .sort{|i1, i2| i1["projectposition"] <=> i2["projectposition"] }
                        .first(10)
            uuids = items.map{|item| item["uuid"] }
            packet = {
                "unixtime" => Time.new.to_i,
                "uuids"    => uuids
            }
            File.open(filepath,  "w"){|f| f.puts(JSON.pretty_generate(packet)) }
            items
        }

        if Config::getOrNull("isLeaderInstance") then
            items = getRecentDataOrNull.call(filepath)
            return items if items
            return issueNewFile.call(filepath, tcId)
        else
            return (getDataOrNull.call(filepath) || [])
        end
    end

    # NxTimeCommitments::nextPositionForItem(tcId)
    def self.nextPositionForItem(tcId)
        ([0] + NxTodos::itemsForNxTimeCommitment(tcId).map{|todo| todo["projectposition"] }).max + 1
    end

    # NxTimeCommitments::numbers(project)
    def self.numbers(project)
        Ax39::standardAx39CarrierNumbers(project)
    end

    # NxTimeCommitments::itemWithToAllAssociatedListingItems(project)
    def self.itemWithToAllAssociatedListingItems(project)

        makeVx01 = lambda {|project|
            uuid = Digest::SHA1.hexdigest("0BCED4BA-4FCC-405A-8B06-EB5359CBFC75")
            {
                "uuid"        => uuid,
                "mikuType"    => "Vx01",
                "unixtime"    => Time.new.to_f,
                "description" => "Main focus for project '#{NxTimeCommitments::toString(project)}'",
                "tcId"   => project["uuid"]
            }
        }

        items = NxTimeCommitments::firstNxTodoItemsForNxTimeCommitment(project["uuid"])
        if items.size > 0 then
            [makeVx01.call(project)] + items
        else
            [project]
        end
    end

    # NxTimeCommitments::totalMissingHoursForToday()
    def self.totalMissingHoursForToday()
        NxTimeCommitments::items()
            .map{|item| NxTimeCommitments::numbers(item)["missingHoursForToday"] }
            .inject(0, :+)
    end


    # --------------------------------------------
    # Ops

    # NxTimeCommitments::interactivelySelectNxTimeCommitmentOrNull()
    def self.interactivelySelectNxTimeCommitmentOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", NxTimeCommitments::items(), lambda{|project| NxTimeCommitments::toStringWithDetails(project, true)})
    end

    # NxTimeCommitments::interactivelySelectProject()
    def self.interactivelySelectProject()
        loop {
            project = NxTimeCommitments::interactivelySelectNxTimeCommitmentOrNull()
            return project if project
        }
    end

    # NxTimeCommitments::presentProjectItems(project)
    def self.presentProjectItems(project)
        items = NxTodos::itemsForNxTimeCommitment(project["uuid"])
        loop {
            system("clear")
            # We do not recompute all the items but we recall the ones we had to get the new 
            # projectpositions
            items = items
                        .map{|item| NxTodos::getOrNull(item["uuid"]) }
                        .sort{|i1, i2| i1["projectposition"] <=> i2["projectposition"] }
            store = ItemStore.new()
            puts ""
            items
                .first(CommonUtils::screenHeight() - 4)
                .each{|item|
                    store.register(item, false)
                    puts "- (#{store.prefixString().to_s.rjust(2)}, #{"%7.3f" % item["projectposition"]}) #{NxTodos::toString(item)}"
                }
            puts ""
            puts "set position <index> <position>"
            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""
            if command.start_with?("set position") then
                command = command.strip[12, command.size]
                elements = command.split(" ")
                #puts JSON.generate(elements)
                indx = elements[0].to_i
                position = elements[1].to_f
                item = store.get(indx)
                #puts item
                next if item.nil?
                item["projectposition"] = position
                NxTodos::commit(item)
            end
        }
    end

    # NxTimeCommitments::probe(project)
    def self.probe(project)
        loop {
            puts NxTimeCommitments::toStringWithDetails(project, false)
            puts "data: #{Ax39::standardAx39CarrierNumbers(project)}"
            actions = ["start", "add time", "do not show until", "set Ax39", "expose", "items dive", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "start" then
                PolyActions::start(project)
                return
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "adding #{timeInHours} hours to '#{NxTimeCommitments::toString(project)}'"
                Bank::put(project["uuid"], timeInHours*3600)
            end
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(project["uuid"], unixtime)
            end
            if action == "set Ax39" then
                project["ax39"] = Ax39::interactivelyCreateNewAx()
                FileSystemCheck::fsck_NxTimeCommitment(project, true)
                NxTimeCommitments::commit(project)
            end
            if action == "expose" then
                puts JSON.pretty_generate(project)
                LucilleCore::pressEnterToContinue()
            end
            if action == "items dive" then
                NxTimeCommitments::presentProjectItems(project)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTimeCommitment '#{NxTimeCommitments::toString(project)}' ? ") then
                    filepath = "#{Config::pathToDataCenter()}/NxTimeCommitment/#{project["uuid"]}.json"
                    FileUtils.rm(filepath)
                    return
                end
            end
        }
    end

    # NxTimeCommitments::mainprobe()
    def self.mainprobe()
        loop {
            system("clear")
            project = NxTimeCommitments::interactivelySelectNxTimeCommitmentOrNull()
            return if project.nil?
            NxTimeCommitments::probe(project)
        }
    end

    # NxTimeCommitments::interactivelyDecideProjectPosition(tcId)
    def self.interactivelyDecideProjectPosition(tcId)
        NxTodos::itemsForNxTimeCommitment(tcId)
            .sort{|i1, i2| i1["projectposition"] <=> i2["projectposition"] }
            .first(CommonUtils::screenHeight() - 2)
            .each{|item|
                puts "- (#{"%7.3f" % item["projectposition"]}) #{NxTodos::toString(item)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("position (default to next): ")
        if position then
            position.to_f
        else
            NxTimeCommitments::nextPositionForItem(tcId)
        end
    end
end

class NxTCTimeLoads

    # NxTCTimeLoads::getTimeLoadInSeconds(tcuuid)
    def self.getTimeLoadInSeconds(tcuuid)
        filepath = "#{Config::pathToDataCenter()}/NxTimeCommitment-DayTimeLoads/TimeLoads/#{tcuuid}.txt"
        return 0 if !File.exists?(filepath)
        IO.read(filepath).strip.to_f
    end

    # NxTCTimeLoads::setTimeLoadInSeconds(tcuuid, value)
    def self.setTimeLoadInSeconds(tcuuid, value)
        filepath = "#{Config::pathToDataCenter()}/NxTimeCommitment-DayTimeLoads/TimeLoads/#{tcuuid}.txt"
        File.open(filepath, "w"){|f| f.puts(value) }
    end

    # NxTCTimeLoads::itemIsFullToday(item)
    def self.itemIsFullToday(item)
        Bank::valueAtDate(item["uuid"], CommonUtils::today(), NxBalls::itemUnrealisedRunTimeInSecondsOrNull(item)) >= NxTCTimeLoads::getTimeLoadInSeconds(item["uuid"])
    end

    # NxTCTimeLoads::totalMissingHoursForToday()
    def self.totalMissingHoursForToday()
        NxTimeCommitments::items()
            .map{|item| NxTCTimeLoads::getTimeLoadInSeconds(item["uuid"]) }
            .inject(0, :+)
            .to_f/3600
    end

    # NxTCTimeLoads::itemsThatShouldBeListed()
    def self.itemsThatShouldBeListed()
        NxTimeCommitments::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|item| !NxTCTimeLoads::itemIsFullToday(item) }
    end
end

class NxTCSpeedOfLight

    # NxTCSpeedOfLight::getDaySpeedOfLightOrNull()
    def self.getDaySpeedOfLightOrNull()
        filepath = "#{Config::pathToDataCenter()}/NxTimeCommitment-DayTimeLoads/speedOfLight.json"
        return nil if !File.exists?(filepath)
        data = JSON.parse(IO.read(filepath))
        # data: {date, value}
        return nil if data["date"] != CommonUtils::today()
        data["speed"]
    end

    # NxTCSpeedOfLight::issueSpeedOfLightForTheDay(timeInHours)
    def self.issueSpeedOfLightForTheDay(timeInHours)
        total = NxTimeCommitments::totalMissingHoursForToday()
        speed = 
            if total > 0 then
                available = timeInHours
                available.to_f/total
            else
                1
            end
        data = { "date" => CommonUtils::today(), "speed" => speed }
        filepath = "#{Config::pathToDataCenter()}/NxTimeCommitment-DayTimeLoads/speedOfLight.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
        speed
    end

    # NxTCSpeedOfLight::interactivelySetSpeedOfLightAndTimeloadsForTheDay()
    def self.interactivelySetSpeedOfLightAndTimeloadsForTheDay()
        timeInHours = LucilleCore::askQuestionAnswerAsString("Time available in hours: ").to_f
        speed = NxTCSpeedOfLight::issueSpeedOfLightForTheDay(timeInHours)
        NxTimeCommitments::items()
            .each{|item| 
                numbers = NxTimeCommitments::numbers(item)
                NxTCTimeLoads::setTimeLoadInSeconds(item["uuid"], numbers["missingHoursForToday"]*3600*speed)
            }
    end
end

class NxTCDataForListing

    # NxTCDataForListing::summaryLine()
    def self.summaryLine()
        todayMissingInHours = NxTCTimeLoads::totalMissingHoursForToday()
        "> pending today: #{"%5.2f" % todayMissingInHours} hours, projected end: #{Time.at( Time.new.to_i + todayMissingInHours*3600 ).to_s}"
    end

    # NxTCDataForListing::reportItemsX()
    def self.reportItemsX()
        return [] if NxTCSpeedOfLight::getDaySpeedOfLightOrNull().nil?
        NxTCTimeLoads::itemsThatShouldBeListed()
            .sort{|i1, i2| NxTCTimeLoads::getTimeLoadInSeconds(i1["uuid"]) <=>  NxTCTimeLoads::getTimeLoadInSeconds(i2["uuid"]) }
    end

    # NxTCDataForListing::listingItems()
    def self.listingItems()
        if NxTCSpeedOfLight::getDaySpeedOfLightOrNull().nil? then
            return [LambdX1s::make("f8cb8290-3ba0-48e0-b482-8f9c26aad869", "configure speed of light", lambda { NxTCSpeedOfLight::interactivelySetSpeedOfLightAndTimeloadsForTheDay() })]
        end
        NxTCTimeLoads::itemsThatShouldBeListed()
            .map{|project| NxTimeCommitments::itemWithToAllAssociatedListingItems(project) }
            .flatten
    end
end
