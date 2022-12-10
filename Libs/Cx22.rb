
class Cx22

    # Cx22::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/Cx22"
        items = LucilleCore::locationsAtFolder(folderpath)
                .select{|filepath| filepath[-5, 5] == ".json" }
                .map{|filepath| JSON.parse(IO.read(filepath)) }
        XCache::set("Cx22-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E", items.map{|item| item["description"].size}.max)
        items
    end

    # Cx22::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/Cx22/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Cx22::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = "#{Config::pathToDataCenter()}/Cx22/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # --------------------------------------------
    # Makers

    # Cx22::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Cx22",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39,
            "isWork"      => false
        }
        FileSystemCheck::fsck_Cx22(item, true)
        Cx22::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # Cx22::cx22Ordered()
    def self.cx22Ordered()
        Cx22::items()
            .sort{|i1, i2| Ax39::standardAx39CarrierOperationalRatio(i1) <=> Ax39::standardAx39CarrierOperationalRatio(i2) }
    end

    # Cx22::cx22OrderedOperations()
    def self.cx22OrderedOperations()
        Cx22::cx22Ordered()
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|cx22| Ax39::standardAx39CarrierOperationalRatio(cx22) < 1 }
    end

    # Cx22::toString(item)
    def self.toString(item)
        "(Cx22) #{item["description"]}"
    end

    # Cx22::toStringWithDetails(item)
    def self.toStringWithDetails(item)
        percentage = 100 * Ax39::standardAx39CarrierOperationalRatio(item)
        percentageStr = ": #{percentage.to_i.to_s.rjust(3)} %"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ": (do not show until: #{datetimeOpt})" : ""

        "#{item["description"]} : #{Ax39::toString(item["ax39"])}#{percentageStr}#{dnsustr}"
    end

    # Cx22::toStringWithDetailsFormatted(item)
    def self.toStringWithDetailsFormatted(item)
        descriptionPadding = (XCache::getOrNull("Cx22-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 28).to_i # the original value
        percentage = 100 * Ax39::standardAx39CarrierOperationalRatio(item)
        percentageStr = ": #{percentage.to_i.to_s.rjust(3)} %"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ": (do not show until: #{datetimeOpt})" : ""

        "(group) #{item["description"].ljust(descriptionPadding)} : #{Ax39::toString(item["ax39"]).ljust(18)}#{percentageStr}#{dnsustr}"
    end

    # Cx22::toStringForListing(item)
    def self.toStringForListing(item)
        descriptionPadding = (XCache::getOrNull("Cx22-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 28).to_i # the original value
        percentage = 100 * Ax39::standardAx39CarrierOperationalRatio(item)
        percentageStr = ": #{percentage.to_i.to_s.rjust(3)} %"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ": (do not show until: #{datetimeOpt})" : ""

        "(Cx22) #{item["description"].ljust(descriptionPadding)} : #{Ax39::toString(item["ax39"]).ljust(18)}#{percentageStr}#{dnsustr}"
    end

    # Cx22::itemsInCompletionOrder()
    def self.itemsInCompletionOrder()
        Cx22::items()
            .map{|cx22|  
                {
                    "cx22"  => cx22,
                    "ratio" => Ax39::standardAx39CarrierOperationalRatio(cx22)
                }
            }
            .sort{|p1, p2| p1["ratio"] <=> p2["ratio"] }
            .map{|packet| packet["cx22"] }
    end

    # Cx22::markHasItems(cx22)
    def self.markHasItems(cx22)
        XCache::set("9af5b072-a5d2-41bd-b512-03928ce56b76:#{cx22["uuid"]}", Time.new.to_i)
    end

    # Cx22::hasItems(cx22)
    def self.hasItems(cx22)
        unixtime = XCache::getOrNull("9af5b072-a5d2-41bd-b512-03928ce56b76:#{cx22["uuid"]}")
        return false if unixtime.nil?
        (Time.new.to_i - unixtime.to_i) < 3600
    end

    # Cx22::workOnlyListingItems(recomputeStuffIfNeeded)
    def self.workOnlyListingItems(recomputeStuffIfNeeded)
        mainFocusItem = lambda{|cx22|
            uuid = "Vx01-#{cx22["uuid"]}-MainFocus"
            ItemToCx22::set(uuid, cx22["uuid"])
            ratio = Ax39::standardAx39CarrierOperationalRatio(cx22)
            shouldShow = ratio < 0.75
            return nil if !shouldShow
            {
                "uuid"        => uuid,
                "mikuType"    => "Vx01",
                "unixtime"    => cx22["unixtime"],
                "description" => "Main Focus, non itemized, for '#{Cx22::toString(cx22)}' (current ratio: #{ratio.round(2)}, until: 0.75)"
            }
        }

        Cx22::cx22OrderedOperations()
            .select{|cx22| cx22["isWork"] }
            .map{|cx22| [mainFocusItem.call(cx22)].compact + NxTodos::firstItemsForCx22(cx22, recomputeStuffIfNeeded) + [cx22]}
            .flatten
    end

    # Cx22::listingItems(recomputeStuffIfNeeded)
    def self.listingItems(recomputeStuffIfNeeded)
        Cx22::cx22OrderedOperations()
            .select{|cx22| !cx22["isWork"] }
            .map{|cx22| NxTodos::firstItemsForCx22(cx22, recomputeStuffIfNeeded) + [cx22]}
            .flatten
    end

    # --------------------------------------------
    # Ops

    # Cx22::interactivelySelectCx22OrNull()
    def self.interactivelySelectCx22OrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cx22", Cx22::cx22Ordered(), lambda{|cx22| Cx22::toStringWithDetailsFormatted(cx22)})
    end

    # Cx22::probe(cx22)
    def self.probe(cx22)
        loop {
            puts Cx22::toStringWithDetails(cx22)
            actions = ["add time", "do not show until", "set Ax39", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "adding #{timeInHours} hours to '#{Cx22::toString(cx22)}'"
                Bank::put(cx22["uuid"], timeInHours*3600)
            end
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(cx22["uuid"], unixtime)
            end
            if action == "set Ax39" then
                cx22["ax39"] = Ax39::interactivelyCreateNewAx()
                FileSystemCheck::fsck_Cx22(cx22, true)
                Cx22::commit(cx22)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy Cx22 '#{Cx22::toString(cx22)}' ? ") then
                    filepath = "#{Config::pathToDataCenter()}/Cx22/#{cx22["uuid"]}.json"
                    FileUtils.rm(filepath)
                    return
                end
            end
        }
    end

    # Cx22::mainprobe()
    def self.mainprobe()
        loop {
            system("clear")
            cx22 = Cx22::interactivelySelectCx22OrNull()
            return if cx22.nil?
            Cx22::probe(cx22)
        }
    end
end
