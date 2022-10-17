
class Cx22

    # Cx22::items()
    def self.items()
        PhagePublic::mikuTypeToObjects("Cx22")
    end

    # Cx22::getOrNull(uuid)
    def self.getOrNull(uuid)
        PhagePublic::getObjectOrNull(uuid)
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
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "mikuType"    => "Cx22",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "bankaccount" => SecureRandom.uuid,
            "ax39"        => ax39
        }
        FileSystemCheck::fsck_Cx22(item, true)
        PhagePublic::commit(item)
        item
    end

    # Cx22::interactivelySelectCx22OrNull()
    def self.interactivelySelectCx22OrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cx22", Cx22::items(), lambda{|cx22| cx22["description"]})
    end

    # Cx22::interactivelySelectCx22OrNullDiveStyle()
    def self.interactivelySelectCx22OrNullDiveStyle()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cx22", Cx22::items(), lambda{|cx22| Cx22::toStringDiveStyle(cx22)})
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

    # Cx22::toString(cx22)
    def self.toString(cx22)
        "(group: #{cx22["description"]})"
    end

    # Cx22::toStringFromUUID(uuid)
    def self.toStringFromUUID(uuid)
        cx22 = Cx22::getOrNull(uuid)
        if cx22.nil? then
            return "(no cx22 found for uuid: #{uuid})"
        end
        Cx22::toString(cx22)
    end

    # Cx22::toStringDiveStyle(cx22)
    def self.toStringDiveStyle(cx22)
        percentage = 100 * Ax39::completionRatio(cx22["ax39"], cx22["bankaccount"])
        percentageStr = "#{percentage.to_i.to_s.rjust(3)} %"
        isDoneToday = BankAccountDoneForToday::isDoneToday(cx22["bankaccount"])
        isDoneTodayStr = isDoneToday ? "(is done today)" : "               "
        "#{cx22["description"].ljust(28)} , #{Ax39::toString(cx22["ax39"]).ljust(18)}, #{percentageStr} , #{isDoneTodayStr}"
    end

    # Cx22::cx22WithCompletionRatiosOrdered()
    def self.cx22WithCompletionRatiosOrdered()
        cx22s = Cx22::items()
        packets = cx22s
                    .map{|cx22|
                        {
                            "mikuType"        => "Cx22WithCompletionRatio",
                            "cx22"            => cx22,
                            "completionratio" => Ax39::completionRatio(cx22["ax39"], cx22["bankaccount"])
                        }
                    }
                    .sort{|p1, p2| p1["completionratio"] <=> p2["completionratio"] }
        packets
    end

    # --------------------------------------------
    # Ops

    # Cx22::interactivelySetANewContributionForItemOrNothing(item) # item
    def self.interactivelySetANewContributionForItemOrNothing(item)
        cx22 = Cx22::architectOrNull()
        return if cx22.nil?
        PhagePublic::setAttribute2(item["uuid"], "cx22", cx22["uuid"])
        PhagePublic::getObjectOrNull(item["uuid"])
    end

    # Cx22::interactivelySetANewContributionForItemWithPositionOrNothing(item) # item
    def self.interactivelySetANewContributionForItemWithPositionOrNothing(item)
        cx22 = Cx22::architectOrNull()
        return if cx22.nil?
        PhagePublic::setAttribute2(item["uuid"], "cx22", cx22["uuid"])
        item = PhagePublic::getObjectOrNull(item["uuid"])
        Cx23::interactivelySetCx23ForItemOrNothing(item)
    end

    # Cx22::nextPositionForCx22(cx22)
    def self.nextPositionForCx22(cx22)
        (NxTodos::items()
            .select{|item| item["cx22"] }
            .select{|item| item["cx22"] == cx22["uuid"] }
            .select{|item| item["cx23"] }
            .map{|item| item["cx23"]["position"] } + [0]).max
    end

    # Cx22::elementsDive(cx22)
    def self.elementsDive(cx22)
        loop {
            system("clear")
            puts ""
            puts Cx22::toString(cx22)
            puts ""
            elements = NxTodos::itemsInPositionOrderForGroup(cx22).first(CommonUtils::screenHeight() - 8)
            store = ItemStore.new()
            elements
                .each{|element|
                    store.register(element, false)
                    if NxBallsService::isActive(NxBallsService::itemToNxBallOpt(element)) then
                        puts "#{store.prefixString()} #{PolyFunctions::toString(element)}#{NxBallsService::activityStringOrEmptyString(" (", element["uuid"], ")")}".green
                    else
                        puts "#{store.prefixString()} #{PolyFunctions::toString(element)}"
                    end
                }
            puts ""
            puts "<n> | insert | position <n> <position> | start <n> | access <n> | stop <n> | pause <n> | pursue <n> | done <n> | reissue positions sequence | exit".yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"

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
                cx23   =
                    (lambda {
                        loop {
                            position = LucilleCore::askQuestionAnswerAsString("position (or `next`): ")
                            if position == "" then
                                next
                            end
                            if position == "next" then
                                position = Cx22::nextPositionForCx22(cx22) + 1
                                return Cx23::makeCx23(cx22, position)
                            end
                            return Cx23::makeCx23(cx22, position.to_f)
                        }
                    }).call()

                NxTodos::issueFromElements(description, nx113, nx11e, cx22, cx23)
                next
            end

            if input.start_with?("start") then
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
                PhagePublic::setAttribute2(entity["uuid"], "cx23", cx23)
                next
            end

            if input == "reissue positions sequence" then
                NxTodos::itemsInPositionOrderForGroup(cx22).each_with_index{|element, indx|
                    next if element["cx23"].nil?
                    element["cx23"]["position"] = indx
                    PhagePublic::commit(element)
                }
            end
        }
    end

    # Cx22::dive(cx22)
    def self.dive(cx22)
        loop {
            puts Cx22::toString(cx22).green
            puts "completion ratio: #{Ax39::completionRatio(cx22["ax39"], cx22["bankaccount"])}"
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["elements (program)", "start NxBall", "update description", "set: done for the day", "unset: done for the day", "expose", "completion ratio", "add time"])
            break if action.nil?
            if action == "elements (program)" then
                Cx22::elementsDive(cx22)
            end
            if action == "start NxBall" then
                NxBallsService::issue(SecureRandom.uuid, "cx22: #{cx22["description"]}", [cx22["bankaccount"]], 3600)
                next
            end
            if action == "update description" then
                description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
                next if description == ""
                cx22["description"] = description
                PhagePublic::commit(cx22)
                next
            end
            if action == "set: done for the day" then
                bankaccount = cx22["bankaccount"]
                BankAccountDoneForToday::setDoneToday(bankaccount)
                next
            end
            if action == "unset: done for the day" then
                bankaccount = cx22["bankaccount"]
                BankAccountDoneForToday::setUnDoneToday(bankaccount)
                next
            end
            if action == "expose" then
                puts JSON.pretty_generate(cx22)
                LucilleCore::pressEnterToContinue()
                next
            end
            if action == "completion ratio" then
                puts JSON.pretty_generate(cx22)
                ax39     = cx22["ax39"]
                account  = cx22["bankaccount"]
                cr = Ax39::completionRatio(ax39, account)
                puts "completion ratio: #{cr}"
                LucilleCore::pressEnterToContinue()
                next
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                time = timeInHours*3600
                puts "Adding #{time} seconds to #{cx22["bankaccount"]}"
                Bank::put(cx22["bankaccount"], time)
                next
            end
        }
    end

    # Cx22::maindive()
    def self.maindive()
        loop {
            cx22 = Cx22::interactivelySelectCx22OrNullDiveStyle()
            return if cx22.nil?
            Cx22::dive(cx22)
        }
    end
end