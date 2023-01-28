
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
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxTimeFiber",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39
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

        "(fiber) (pending: #{"%5.2f" % pendingInHours}) #{item["description"].ljust(descriptionPadding)} (#{Ax39::toStringFormatted(item["ax39"])})"
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

        items = Database2Data::itemsForTimeFiber(fiber["uuid"])

        if items.size > 0 then
            items.first(3)
        else
            [fiber]
        end
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

    # NxTimeFibers::probe(fiber)
    def self.probe(fiber)
        loop {
            puts NxTimeFibers::toStringWithDetails(fiber, false)
            actions = ["do not show until", "set Ax39", "expose", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
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
end
