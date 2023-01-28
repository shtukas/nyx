
class NxTimeFibers

    # NxTimeFibers::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTimeFiber/#{uuid}.json"
    end

    # NxTimeFibers::items()
    def self.items()
        items = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTimeFiber")
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .map{|filepath| JSON.parse(IO.read(filepath)) }
        XCache::set("NxTimeFiber-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E", items.map{|item| item["description"].size }.max)
        items
    end

    # NxTimeFibers::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxTimeFibers::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxTimeFibers::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxTimeFibers::filepath(uuid)
        return nil if !File.exist?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxTimeFibers::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTimeFibers::filepath(uuid)
        if File.exist?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # Makers

    # NxTimeFibers::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        isWork = LucilleCore::askQuestionAnswerAsBoolean("is work? : ")
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxTimeFiber",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39,
            "isWork"      => isWork
        }
        FileSystemCheck::fsck_NxTimeFiber(item, true)
        NxTimeFibers::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxTimeFibers::toString(item)
    def self.toString(item)
        "(fiber) #{item["description"]}"
    end

    # NxTimeFibers::toStringWithDetails(item, shouldFormat)
    def self.toStringWithDetails(item, shouldFormat)
        descriptionPadding = 
            if shouldFormat then
                (XCache::getOrNull("NxTimeFiber-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 0).to_i
            else
                0
            end

        pendingInHours = NxTimeFibers::liveNumbers(item)["pendingTimeTodayInHoursLive"]

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? " (do not show until: #{datetimeOpt})" : ""

        "(fiber) (pending: #{"%5.2f" % pendingInHours}) #{item["description"].ljust(descriptionPadding)} (#{Ax39::toStringFormatted(item["ax39"])})#{dnsustr}"
    end

    # NxTimeFibers::runningItems()
    def self.runningItems()
        NxTimeFibers::items()
            .select{|fiber| NxBalls::getNxBallForItemOrNull(fiber) }
    end

    # NxTimeFibers::nextPositionForItem(tcId)
    def self.nextPositionForItem(tcId)
        ([0] + NxTodos::itemsForNxTimeFiber(tcId).map{|todo| todo["tcPos"] }).max + 1
    end

    # NxTimeFibers::itemsForListing()
    def self.itemsForListing()
        NxTimeFibers::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|item| NxBalls::itemIsRunning(item) or item["doneForDay"] != CommonUtils::today() }
            .select{|item| NxBalls::itemIsRunning(item) or NxTimeFibers::liveNumbers(item)["pendingTimeTodayInHoursLive"] > 0 }
            .sort{|i1, i2| NxTimeFibers::liveNumbers(i1)["pendingTimeTodayInHoursLive"] <=>  NxTimeFibers::liveNumbers(i2)["pendingTimeTodayInHoursLive"] }
    end

    # NxTimeFibers::itemWithToAllAssociatedListingItems(fiber)
    def self.itemWithToAllAssociatedListingItems(fiber)

        makeVx01 = lambda {|fiber|
            uuid = Digest::SHA1.hexdigest("0BCED4BA-4FCC-405A-8B06-EB5359CBFC75:#{fiber["uuid"]}")
            {
                "uuid"        => uuid,
                "mikuType"    => "Vx01",
                "unixtime"    => Time.new.to_f,
                "description" => "Main focus for fiber '#{NxTimeFibers::toString(fiber)}'",
                "tcId"        => fiber["uuid"]
            }
        }

        items = NxTodos::itemsForNxTimeFiber(fiber["uuid"])

        if fiber["isWork"] then
            [makeVx01.call(fiber)] + items
        else
            if items.size > 0 then
                items
            else
                [fiber]
            end
        end
    end

    # NxTimeFibers::listingElements(isWork)
    def self.listingElements(isWork)
        xor = lambda{|b1, b2| (b1 or b2) and !(b1 and b2) }

        NxTimeFibers::itemsForListing()
            .select{|item| xor.call(!isWork, item["isWork"]) }
            .map{|item| NxTimeFibers::itemWithToAllAssociatedListingItems(item) }
            .flatten
    end

    # NxTimeFibers::allPendingTimeTodayInHoursLive()
    def self.allPendingTimeTodayInHoursLive()
        NxTimeFibers::items()
            .map{|item| NxTimeFibers::liveNumbers(item)["pendingTimeTodayInHoursLive"] }
            .inject(0, :+)
    end

    # --------------------------------------------
    # Ops

    # NxTimeFibers::interactivelySelectItemOrNull()
    def self.interactivelySelectItemOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("fiber", NxTimeFibers::items(), lambda{|fiber| NxTimeFibers::toStringWithDetails(fiber, true)})
    end

    # NxTimeFibers::interactivelySelectItem()
    def self.interactivelySelectItem()
        loop {
            fiber = NxTimeFibers::interactivelySelectItemOrNull()
            return fiber if fiber
        }
    end

    # NxTimeFibers::presentProjectItems(fiber)
    def self.presentProjectItems(fiber)
        items = NxTodos::itemsForNxTimeFiber(fiber["uuid"])
        loop {
            system("clear")
            # We do not recompute all the items but we recall the ones we had to get the new 
            # tcPoss
            items = items
                        .map{|item| NxTodosIO::getOrNull(item["uuid"]) }
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
                NxTodosIO::commit(item)
            end
        }
    end

    # NxTimeFibers::probe(fiber)
    def self.probe(fiber)
        loop {
            puts NxTimeFibers::toStringWithDetails(fiber, false)
            actions = ["start", "do not show until", "set Ax39", "expose", "items dive", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "start" then
                PolyActions::start(fiber)
                return
            end
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(fiber["uuid"], unixtime)
            end
            if action == "set Ax39" then
                fiber["ax39"] = Ax39::interactivelyCreateNewAx()
                FileSystemCheck::fsck_NxTimeFiber(fiber, true)
                NxTimeFibers::commit(fiber)
            end
            if action == "expose" then
                puts JSON.pretty_generate(fiber)
                LucilleCore::pressEnterToContinue()
            end
            if action == "items dive" then
                NxTimeFibers::presentProjectItems(fiber)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTimeFiber '#{NxTimeFibers::toString(fiber)}' ? ") then
                    filepath = "#{Config::pathToDataCenter()}/NxTimeFiber/#{fiber["uuid"]}.json"
                    FileUtils.rm(filepath)
                    return
                end
            end
        }
    end

    # NxTimeFibers::mainprobe()
    def self.mainprobe()
        loop {
            system("clear")
            fiber = NxTimeFibers::interactivelySelectItemOrNull()
            return if fiber.nil?
            NxTimeFibers::probe(fiber)
        }
    end

    # NxTimeFibers::interactivelyDecideProjectPosition(tcId)
    def self.interactivelyDecideProjectPosition(tcId)
        NxTodos::itemsForNxTimeFiber(tcId)
            .sort{|i1, i2| i1["tcPos"] <=> i2["tcPos"] }
            .first(CommonUtils::screenHeight() - 2)
            .each{|item|
                puts "- (#{"%7.3f" % item["tcPos"]}) #{NxTodos::toString(item)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("position (default to next): ")
        if position then
            position.to_f
        else
            NxTimeFibers::nextPositionForItem(tcId)
        end
    end
end
