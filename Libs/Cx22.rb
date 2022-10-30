
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
        FileSystemCheck::fsck_MikuTypedItem(item, SecureRandom.hex, false)
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
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Cx22",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39,
            "style"       => style
        }
        FileSystemCheck::fsck_Cx22(item, true)
        Cx22::commit(item)
        item
    end

    # Cx22::interactivelySelectCx22OrNull()
    def self.interactivelySelectCx22OrNull()
        cx22s = Cx22::cx22WithCompletionRatiosOrdered().map{|packet| packet["item"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cx22", cx22s, lambda{|cx22| Cx22::toStringDiveStyleFormatted(cx22)})
    end

    # Cx22::interactivelySelectCx22OrNullDiveStyle()
    def self.interactivelySelectCx22OrNullDiveStyle()
        cx22s = Cx22::cx22WithCompletionRatiosOrdered().map{|packet| packet["item"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cx22", cx22s, lambda{|cx22| Cx22::toStringDiveStyleFormatted(cx22)})
    end

    # Cx22::architectOrNull()
    def self.architectOrNull()
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return cx22 if cx22
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a new Cx22 ? ", true) then
            return Cx22::interactivelyIssueNewOrNull()
        end
        nil
    end

    # ----------------------------------------------------------------
    # Data

    # Cx22::toString1(item)
    def self.toString1(item)
        "(group) #{item["description"]}"
    end

    # Cx22::toString2(uuid)
    def self.toString2(uuid)
        item = Cx22::getOrNull(uuid)
        return "(Cx22 not found for uuid: #{uuid})" if item.nil?
        Cx22::toString1(item)
    end

    # Cx22::toString3(uuid)
    def self.toString3(uuid)
        item = Cx22::getOrNull(uuid)
        return "(Cx22 not found for uuid: #{uuid})" if item.nil?
        "(group: #{item["description"]})"
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

        "#{item["description"].ljust(descriptionPadding)} : #{Ax39::toString(item["ax39"]).ljust(18)}#{percentageStr}#{dnsustr}"
    end

    # Cx22::cx22WithCompletionRatiosOrdered()
    def self.cx22WithCompletionRatiosOrdered()
        items = Cx22::items()
        packets = items
                    .map{|item|
                        {
                            "mikuType"        => "Cx22WithCompletionRatio",
                            "item"            => item,
                            "completionratio" => Ax39::completionRatio(item["ax39"], item["uuid"])
                        }
                    }
                    .sort{|p1, p2| p1["completionratio"] <=> p2["completionratio"] }
        packets
    end

    # Cx22::listingItems()
    def self.listingItems()
        Cx22::items()
            .select{|cx22| NxTodos::itemsForCx22(cx22).empty? }
    end

    # --------------------------------------------
    # Ops

    # Cx22::nextPositionForCx22(cx22)
    def self.nextPositionForCx22(cx22)
        (NxTodos::items()
            .select{|item| item["cx23"] }
            .select{|item| item["cx23"]["groupuuid"] == cx22["uuid"] }
            .map{|item| item["cx23"]["position"] } + [0]).max + 1
    end

    # Cx22::elementsDive(cx22)
    def self.elementsDive(cx22)
        loop {
            system("clear")
            puts ""
            count1 = 0
            puts Cx22::toStringWithDetails(cx22)
            puts "style: #{cx22["style"]}"
            
            nxballs = NxBallsService::items()
            if nxballs.size > 0 then
                puts ""
                count1 = count1 + 1
                nxballs
                    .each{|nxball|
                        puts "[NxBall] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})".green
                        count1 = count1 + 1
                    }
            end

            puts ""
            elements = NxTodos::itemsInPositionOrderForGroup(cx22)
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
                    cx23str = 
                        if element["cx23"] then
                            " #{"%6.2f" % element["cx23"]["position"]}"
                        else
                            ""
                        end
                    rtstr = [0, 1, 2].include?(indx) ? " (rt: #{BankExtended::stdRecoveredDailyTimeInHours(element["uuid"])})" : ""
                    if NxBallsService::isActive(NxBallsService::itemToNxBallOpt(element)) then
                        puts "#{store.prefixString()}#{cx23str}#{rtstr} #{PolyFunctions::toStringForListing(element)}#{NxBallsService::activityStringOrEmptyString(" (", element["uuid"], ")")}".green
                    else
                        if DoNotShowUntil::isVisible(element["uuid"])  then
                            puts "#{store.prefixString()}#{rtstr} #{PolyFunctions::toStringForListing(element)}"
                        else
                            puts "#{store.prefixString()}#{rtstr} #{PolyFunctions::toStringForListing(element)}".yellow
                        end
                    end
                }
            puts ""
            puts "+(datecode) for index 0 | <n> | insert | position <n> <position> | start <n> | access <n> | stop <n> | pause <n> | pursue <n> | done <n> | expose <n>  | start group | stop group | reissue positions sequence | exit".yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"

            if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                entity = store.get(0)
                next if entity.nil?
                PolyActions::stop(entity)
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
                uuid   = SecureRandom.uuid
                nx11e  = Nx11E::makeStandard()
                nx113  = Nx113Make::interactivelyMakeNx113OrNull()
                cx23   = Cx23::interactivelyMakeNewGivenCx22OrNull(cx22)
                NxTodos::issueFromElements(description, nx113, nx11e, cx23)
                next
            end

            if input.start_with?("start") and input != "start group" then
                indx = input[5, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::start(entity)
                next
            end

            if input.start_with?("access") then
                indx = input[6, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::access(entity)
                next
            end

            if input.start_with?("stop") then
                indx = input[4, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::stop(entity)
                next
            end

            if input.start_with?("pause") then
                indx = input[5, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                NxBallsService::pause(NxBallsService::itemToNxBallOpt(entity))
                next
            end

            if input.start_with?("pursue") then
                indx = input[6, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                NxBallsService::pursue(NxBallsService::itemToNxBallOpt(entity))
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

            if input.start_with?("position") then
                input = input[8, 99].strip
                es = input.split(" ").map{|token| token.strip }
                return if es.size != 2
                indx, position = es
                indx = indx.to_i
                position = position.to_f
                entity = store.get(indx)
                next if entity.nil?
                cx23 = Cx23::makeCx23(cx22, position)
                entity["cx23"] = cx23
                PolyActions::commit(entity)
                next
            end

            if input == "start group" then
                PolyActions::start(cx22)
                next
            end

            if input == "stop group" then
                PolyActions::stop(cx22)
                next
            end

            if input == "reissue positions sequence" then
                NxTodos::itemsInPositionOrderForGroup(cx22).each_with_index{|element, indx|
                    next if element["cx23"].nil?
                    puts JSON.pretty_generate(element)
                    element["cx23"]["position"] = indx
                    PolyActions::commit(element)
                }
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
            nxballs = NxBallsService::items()
            if nxballs.size > 0 then
                nxballs
                    .each{|nxball|
                        puts "[NxBall] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})".green
                    }
            end
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["elements (program)", "start NxBall", "update description", "push (do not display until)", "expose", "add time", "set style", "Destroy Cx22"])
            break if action.nil?
            if action == "elements (program)" then
                Cx22::elementsDive(cx22)
            end
            if action == "start NxBall" then
                NxBallsService::issue(SecureRandom.uuid, "cx22: #{cx22["description"]}", [cx22["uuid"]], 3600)
                next
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
                PolyActions::stop(cx22)
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
            nxballs = NxBallsService::items()
            if nxballs.size > 0 then
                puts ""
                nxballs
                    .each{|nxball|
                        line = "[NxBall] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                        puts line.green
                    }
                puts ""
            end
            cx22 = Cx22::interactivelySelectCx22OrNull()
            return if cx22.nil?
            Cx22::dive(cx22)
        }
    end
end