
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

    # Cx22::interactivelySelectStyle()
    def self.interactivelySelectStyle()
        loop {
            style = LucilleCore::selectEntityFromListOfEntitiesOrNull("Cx22 style", ["sequence", "managed-top-3"])
            return style if style
        }
    end

    # Cx22::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        style = Cx22::interactivelySelectStyle()
        isPriority = LucilleCore::askQuestionAnswerAsBoolean("is priority (work-like commitment) ? : ")
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Cx22",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39,
            "style"       => style,
            "isPriority"  => isPriority
        }
        FileSystemCheck::fsck_Cx22(item, true)
        Cx22::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # Cx22::toString1(item)
    def self.toString1(item)
        "#{item["description"]}"
    end

    # Cx22::toStringWithDetails(item)
    def self.toStringWithDetails(item)
        percentage = 100 * Ax39::completionRatio(item["ax39"], item["uuid"])
        percentageStr = ": #{percentage.to_i.to_s.rjust(3)} %"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ": (do not show until: #{datetimeOpt})" : ""

        "#{item["description"]} : #{Ax39::toString(item["ax39"])}#{percentageStr}#{dnsustr}"
    end

    # Cx22::toStringDiveStyleFormatted(item)
    def self.toStringDiveStyleFormatted(item)
        descriptionPadding = (XCache::getOrNull("Cx22-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 28).to_i # the original value
        percentage = 100 * Ax39::completionRatio(item["ax39"], item["uuid"])
        percentageStr = ": #{percentage.to_i.to_s.rjust(3)} %"

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ": (do not show until: #{datetimeOpt})" : ""

        "(group) #{item["description"].ljust(descriptionPadding)} : #{Ax39::toString(item["ax39"]).ljust(18)}#{percentageStr}#{dnsustr}"
    end

    # Cx22::cx22WithCompletionRatiosOrdered()
    def self.cx22WithCompletionRatiosOrdered()
        items = Cx22::items()
        packets = items
                    .map{|item|
                        {
                            "mikuType"        => "Cx22WithCompletionRatio",
                            "item"            => item,
                            "completionRatio" => Ax39::completionRatio(item["ax39"], item["uuid"])
                        }
                    }
                    .sort{|p1, p2| p1["completionRatio"] <=> p2["completionRatio"] }
        packets
    end

    # Cx22::listingItems()
    def self.listingItems()
        packets = Cx22::items()
                    .map{|cx22|
                        {
                            "item"     => cx22,
                            "priority" => PolyFunctions::listingPriorityOrNull(cx22)
                        }
                    }
                    .select{|packet| !packet["priority"].nil? }
        hasPriorityItems = packets.any?{|packet| packet["item"]["isPriority"] }
        if hasPriorityItems then
            packets = packets.select{|packet| packet["item"]["isPriority"] }
        else
            packets = packets.select{|packet| !packet["item"]["isPriority"] }
        end
        packets.map{|packet| packet["item"] }
    end

    # ----------------------------------------------------------------
    # Elements

    # Cx22::addItemToCx22(cx22uuid, itemuuid)
    def self.addItemToCx22(cx22uuid, itemuuid)
        folderpath = "#{Config::pathToDataCenter()}/Cx22/#{cx22uuid}"
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        filepath = "#{folderpath}/#{itemuuid}"
        FileUtils.touch(filepath)
    end

    # Cx22::getItemsUUIDsForCx22(cx22uuid)
    def self.getItemsUUIDsForCx22(cx22uuid)
        folderpath = "#{Config::pathToDataCenter()}/Cx22/#{cx22uuid}"
        return [] if !File.exists?(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[0, 1] != "." }
            .map{|filepath| File.basename(filepath) }
    end

    # Cx22::getItemsForCx22(cx22uuid)
    def self.getItemsForCx22(cx22uuid)
        Cx22::getItemsUUIDsForCx22(cx22uuid)
            .map{|itemuuid| Catalyst::getCatalystItemOrNull(itemuuid) }
            .compact
    end

    # Cx22::getCx22ForItemUUIDOrNull(itemuuid)
    def self.getCx22ForItemUUIDOrNull(itemuuid)
        Cx22::items().each{|cx22|
            if Cx22::getItemsUUIDsForCx22(cx22["uuid"]).include?(itemuuid) then
                return cx22
            end
        }
        nil
    end

    # Cx22::itemuuidFilepathAtCx22(cx22uuid, itemuuid)
    def self.itemuuidFilepathAtCx22(cx22uuid, itemuuid)
        "#{Config::pathToDataCenter()}/Cx22/#{cx22uuid}/#{itemuuid}"
    end

    # Cx22::garbageCollection(itemuuid)
    def self.garbageCollection(itemuuid)
        Cx22::items().each{|cx22|
            filepath = Cx22::itemuuidFilepathAtCx22(cx22["uuid"], itemuuid)
            next if !File.exists?(filepath)
            FileUtils.rm(filepath)
        }
    end

    # --------------------------------------------
    # Ops

    # Cx22::interactivelySelectCx22OrNull()
    def self.interactivelySelectCx22OrNull()
        cx22s = Cx22::cx22WithCompletionRatiosOrdered().map{|packet| packet["item"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cx22", cx22s, lambda{|cx22| Cx22::toStringDiveStyleFormatted(cx22)})
    end

    # Cx22::addItemToInteractivelySelectedCx22(itemuuid)
    def self.addItemToInteractivelySelectedCx22(itemuuid)
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return if  cx22.nil?
        Cx22::addItemToCx22(cx22["uuid"], itemuuid)
    end

    # Cx22::elementsDive(cx22)
    def self.elementsDive(cx22)
        loop {
            system("clear")
            puts ""
            count1 = 0
            puts Cx22::toStringWithDetails(cx22)
            puts "style: #{cx22["style"]}"

            puts ""
            elements = Cx22::getItemsForCx22(cx22["uuid"])
                            .select{|element| element["mikuType"] == "NxTodo" }
                            .select{|element| DoNotShowUntil::isVisible(element["uuid"]) }
                            .first(CommonUtils::screenHeight() - (10+count1))

            if cx22["style"] == "managed-top-3" then
                theRTWeDeserve = lambda {|element|
                    rt = BankExtended::stdRecoveredDailyTimeInHours(element["uuid"])
                    return 0.4 if (rt == 0)
                    rt
                }
                es1s = elements
                        .take(3)
                        .sort{|element1, element2| theRTWeDeserve.call(element1) <=> theRTWeDeserve.call(element2) }
                es2s = elements.drop(3)
                elements = es1s + es2s
            end

            store = ItemStore.new()
            elements
                .each_with_index{|element, indx|
                    store.register(element, false)
                    rtstr   = [0, 1, 2].include?(indx) ? " (rt: #{BankExtended::stdRecoveredDailyTimeInHours(element["uuid"])})" : ""
                    if DoNotShowUntil::isVisible(element["uuid"])  then
                        puts "#{store.prefixString()}#{rtstr} #{PolyFunctions::toStringForListing(element)}"
                    else
                        puts "#{store.prefixString()}#{rtstr} #{PolyFunctions::toStringForListing(element)}".yellow
                    end
                }
            puts ""
            puts "+(datecode) for index 0 | <n> | insert | access <n> | done <n> | expose <n> | exit".yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"

            if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                entity = store.get(0)
                next if entity.nil?
                DoNotShowUntil::setUnixtime(entity["uuid"], unixtime)
            end

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::landing(entity)
                next
            end

            if Interpreting::match("insert", input) then
                description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
                next if description == ""
                uuid  = SecureRandom.uuid
                nx11e = Nx11E::makeStandard()
                nx113 = Nx113Make::interactivelyMakeNx113OrNull(NxTodos::getElizabethOperatorForUUID(uuid))
                Cx22::addItemToCx22(cx22["uuid"], uuid)
                NxTodos::issueFromElements(uuid, description, nx113, nx11e)
                next
            end

            if input.start_with?("access") then
                indx = input[6, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::access(entity)
                next
            end

            if input.start_with?("done") then
                indx = input[4, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::done(entity)
                next
            end

            if input.start_with?("expose") then
                indx = input[6, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                puts JSON.pretty_generate(entity)
                LucilleCore::pressEnterToContinue()
                next
            end
        }
    end

    # Cx22::dive(cx22)
    def self.dive(cx22)
        loop {
            system("clear")
            puts Cx22::toStringWithDetails(cx22)
            puts "DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(cx22["uuid"])}"
            puts "style: #{cx22["style"]}"
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["elements (program)", "update description", "push (do not display until)", "expose", "add time", "set style", "Destroy Cx22"])
            break if action.nil?
            if action == "elements (program)" then
                Cx22::elementsDive(cx22)
            end
            if action == "update description" then
                description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
                next if description == ""
                cx22["description"] = description
                PolyActions::commit(cx22)
                next
            end
            if action == "push (do not display until)" then
                datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
                next if datecode == ""
                unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(cx22["uuid"], unixtime)
            end
            if action == "expose" then
                puts JSON.pretty_generate(cx22)
                LucilleCore::pressEnterToContinue()
                next
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                time = timeInHours*3600
                puts "Adding #{time} seconds to #{cx22["uuid"]}"
                Bank::put(cx22["uuid"], time)
                next
            end
            if action == "set style" then
                style = Cx22::interactivelySelectStyle()
                cx22["style"] = style
                PolyActions::commit(cx22)
                next
            end
            if action == "Destroy Cx22" then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy '#{Cx22::toString1(cx22).green}' ? ") then
                    filepath = "#{Config::pathToDataCenter()}/Cx22/#{cx22["uuid"]}.json"
                    FileUtils.rm(filepath)
                end
                return
            end
        }
    end

    # Cx22::maindive()
    def self.maindive()
        loop {
            system("clear")
            cx22 = Cx22::interactivelySelectCx22OrNull()
            return if cx22.nil?
            Cx22::dive(cx22)
        }
    end
end
