
class NxWTimeCommitments

    # NxWTimeCommitments::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxWTimeCommitment/#{uuid}.json"
    end

    # NxWTimeCommitments::items()
    def self.items()
        items = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxWTimeCommitment")
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .map{|filepath| JSON.parse(IO.read(filepath)) }
        XCache::set("NxWTimeCommitment-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E", items.map{|item| item["description"].size }.max)
        items
    end

    # NxWTimeCommitments::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxWTimeCommitments::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxWTimeCommitments::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxWTimeCommitments::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxWTimeCommitments::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxWTimeCommitments::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # Makers

    # NxWTimeCommitments::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        isWork = LucilleCore::askQuestionAnswerAsBoolean("is work? : ")
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxWTimeCommitment",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39,
            "isWork"      => isWork
        }
        FileSystemCheck::fsck_NxWTimeCommitment(item, true)
        NxWTimeCommitments::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxWTimeCommitments::toString(item)
    def self.toString(item)
        "(wtc) #{item["description"]}"
    end

    # NxWTimeCommitments::toStringWithDetails(item, shouldFormat)
    def self.toStringWithDetails(item, shouldFormat)
        descriptionPadding = 
            if shouldFormat then
                (XCache::getOrNull("NxWTimeCommitment-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 0).to_i
            else
                0
            end

        pending = NxWTCTodayTimeLoads::itemLiveTimeThatShouldBeDoneTodayInHours(item).to_f/3600

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ", (do not show until: #{datetimeOpt})" : ""

        "(wtc) (pending: #{"%5.2f" % pending}) #{item["description"].ljust(descriptionPadding)} (#{Ax39::toStringFormatted(item["ax39"])})#{dnsustr}"
    end

    # NxWTimeCommitments::runningItems()
    def self.runningItems()
        NxWTimeCommitments::items()
            .select{|wtc| NxBalls::getNxBallForItemOrNull(wtc) }
    end

    # NxWTimeCommitments::firstNxTodoItemsForNxWTimeCommitment(tcId)
    def self.firstNxTodoItemsForNxWTimeCommitment(tcId)
        filepath = "#{Config::pathToDataCenter()}/NxWTimeCommitment-to-FirstItems/#{tcId}.json"

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
            items = NxTodos::itemsForNxWTimeCommitment(tcId)
                        .sort{|i1, i2| i1["tcPos"] <=> i2["tcPos"] }
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

    # NxWTimeCommitments::nextPositionForItem(tcId)
    def self.nextPositionForItem(tcId)
        ([0] + NxTodos::itemsForNxWTimeCommitment(tcId).map{|todo| todo["tcPos"] }).max + 1
    end

    # NxWTimeCommitments::liveNumbers(wtc)
    def self.liveNumbers(wtc)
        Ax39::standardAx39CarrierLiveNumbers(wtc)
    end

    # NxWTimeCommitments::itemWithToAllAssociatedListingItems(wtc)
    def self.itemWithToAllAssociatedListingItems(wtc)

        makeVx01 = lambda {|wtc|
            uuid = Digest::SHA1.hexdigest("0BCED4BA-4FCC-405A-8B06-EB5359CBFC75")
            {
                "uuid"        => uuid,
                "mikuType"    => "Vx01",
                "unixtime"    => Time.new.to_f,
                "description" => "Main focus for wtc '#{NxWTimeCommitments::toString(wtc)}'",
                "tcId"        => wtc["uuid"]
            }
        }

        items = NxWTimeCommitments::firstNxTodoItemsForNxWTimeCommitment(wtc["uuid"])

        if wtc["isWork"] then
            [makeVx01.call(wtc)] + items
        else
            if items.size > 0 then
                items
            else
                [wtc]
            end
        end
    end

    # --------------------------------------------
    # Ops

    # NxWTimeCommitments::interactivelySelectNxWTimeCommitmentOrNull()
    def self.interactivelySelectNxWTimeCommitmentOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wtc", NxWTimeCommitments::items(), lambda{|wtc| NxWTimeCommitments::toStringWithDetails(wtc, true)})
    end

    # NxWTimeCommitments::interactivelySelectItem()
    def self.interactivelySelectItem()
        loop {
            wtc = NxWTimeCommitments::interactivelySelectNxWTimeCommitmentOrNull()
            return wtc if wtc
        }
    end

    # NxWTimeCommitments::presentProjectItems(wtc)
    def self.presentProjectItems(wtc)
        items = NxTodos::itemsForNxWTimeCommitment(wtc["uuid"])
        loop {
            system("clear")
            # We do not recompute all the items but we recall the ones we had to get the new 
            # tcPoss
            items = items
                        .map{|item| NxTodos::getOrNull(item["uuid"]) }
                        .sort{|i1, i2| i1["tcPos"] <=> i2["tcPos"] }
            store = ItemStore.new()
            puts ""
            items
                .first(CommonUtils::screenHeight() - 4)
                .each{|item|
                    store.register(item, false)
                    puts "- (#{store.prefixString().to_s.rjust(2)}, #{"%7.3f" % item["tcPos"]}) #{NxTodos::toString(item)}"
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
                item["tcPos"] = position
                NxTodos::commit(item)
            end
        }
    end

    # NxWTimeCommitments::probe(wtc)
    def self.probe(wtc)
        loop {
            puts NxWTimeCommitments::toStringWithDetails(wtc, false)
            puts "data: #{Ax39::standardAx39CarrierLiveNumbers(wtc)}"
            actions = ["start", "add time", "do not show until", "provision today time", "set Ax39", "expose", "items dive", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "start" then
                PolyActions::start(wtc)
                return
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "adding #{timeInHours} hours to '#{NxWTimeCommitments::toString(wtc)}'"
                Bank::put(wtc["uuid"], timeInHours*3600)
            end
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(wtc["uuid"], unixtime)
            end
            if action == "provision today time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                NxWTCTodayTimeLoads::commitTodayManuallySubmittedTimeProvision(wtc, timeInHours)
            end
            if action == "set Ax39" then
                wtc["ax39"] = Ax39::interactivelyCreateNewAx()
                FileSystemCheck::fsck_NxWTimeCommitment(wtc, true)
                NxWTimeCommitments::commit(wtc)
            end
            if action == "expose" then
                puts JSON.pretty_generate(wtc)
                LucilleCore::pressEnterToContinue()
            end
            if action == "items dive" then
                NxWTimeCommitments::presentProjectItems(wtc)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxWTimeCommitment '#{NxWTimeCommitments::toString(wtc)}' ? ") then
                    filepath = "#{Config::pathToDataCenter()}/NxWTimeCommitment/#{wtc["uuid"]}.json"
                    FileUtils.rm(filepath)
                    return
                end
            end
        }
    end

    # NxWTimeCommitments::mainprobe()
    def self.mainprobe()
        loop {
            system("clear")
            wtc = NxWTimeCommitments::interactivelySelectNxWTimeCommitmentOrNull()
            return if wtc.nil?
            NxWTimeCommitments::probe(wtc)
        }
    end

    # NxWTimeCommitments::interactivelyDecideProjectPosition(tcId)
    def self.interactivelyDecideProjectPosition(tcId)
        NxTodos::itemsForNxWTimeCommitment(tcId)
            .sort{|i1, i2| i1["tcPos"] <=> i2["tcPos"] }
            .first(CommonUtils::screenHeight() - 2)
            .each{|item|
                puts "- (#{"%7.3f" % item["tcPos"]}) #{NxTodos::toString(item)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("position (default to next): ")
        if position then
            position.to_f
        else
            NxWTimeCommitments::nextPositionForItem(tcId)
        end
    end
end

class NxWTCTodayTimeLoads

    # NxWTCTodayTimeLoads::commitTodayManuallySubmittedTimeProvision(wtc, hours)
    def self.commitTodayManuallySubmittedTimeProvision(wtc, hours)
        data = {
            "date"  => CommonUtils::today(),
            "hours" => timeInHours
        }
        puts JSON.pretty_generate(data)
        filepath = "#{Config::pathToDataCenter()}/NxWTimeCommitment-DayTimeLoads/#{wtc["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end

    # NxWTCTodayTimeLoads::itemLiveNumbersUsingManuallySubmittedTimeProvisionIfExistsOrNull(wtc)
    def self.itemLiveNumbersUsingManuallySubmittedTimeProvisionIfExistsOrNull(wtc)
        filepath = "#{Config::pathToDataCenter()}/NxWTimeCommitment-DayTimeLoads/#{wtc["uuid"]}.json"
        return nil if !File.exists?(filepath)
        data = JSON.parse(IO.read(filepath))
        return nil if data["date"] != CommonUtils::today()
        hours = data["hours"]
        timeDoneInSeconds = Bank::valueAtDate(wtc["uuid"], CommonUtils::today(), NxBalls::itemUnrealisedRunTimeInSecondsOrNull(wtc))
        pendingInHours = [hours - timeDoneInSeconds.to_f/3600, 0].max
        {
            "timeThatShouldBeDoneTodayInHours" => pendingInHours,
        }
    end

    # NxWTCTodayTimeLoads::itemLiveTimeThatShouldBeDoneTodayInHours(item)
    def self.itemLiveTimeThatShouldBeDoneTodayInHours(item)

        # This doesn't take speed of light account, is live
        numbers = NxWTCTodayTimeLoads::itemLiveNumbersUsingManuallySubmittedTimeProvisionIfExistsOrNull(item)
        return numbers["timeThatShouldBeDoneTodayInHours"]*3600 if numbers

        # This does use speed of light, is live
        TheSpeedOfLight::getDaySpeedOfLight()*NxWTimeCommitments::liveNumbers(item)["timeThatShouldBeDoneTodayInHours"]*3600
    end

    # NxWTCTodayTimeLoads::typeLiveTimeThatShouldBeDoneTodayInHours()
    def self.typeLiveTimeThatShouldBeDoneTodayInHours()
        NxWTimeCommitments::items()
            .map{|item| NxWTCTodayTimeLoads::itemLiveTimeThatShouldBeDoneTodayInHours(item) }
            .inject(0, :+)
    end
end
