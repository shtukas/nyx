
class PolyPrograms

    # PolyPrograms::catalystMainListing()
    def self.catalystMainListing()
        system("clear")

        context = CatalystListing::getContextOrNull()

        vspaceleft = CommonUtils::screenHeight() - (context ? 4 : 3)

        if Config::get("instanceId") == "Lucille20-pascal" then
            reference = The99Percent::getReferenceOrNull()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
            puts ""
            puts line
            vspaceleft = vspaceleft - 2
            if ratio < 0.99 then
                The99Percent::issueNewReferenceOrNull()
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        if context.nil? then
            tx = TxTimeCommitments::items()
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
                    .select{|item| InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
                    .select{|item| Ax39forSections::itemShouldShow(item) or NxBallsService::isPresent(item["uuid"]) }
            if tx.size > 0 then
                puts ""
                vspaceleft = vspaceleft - 1
                tx
                    .each{|item|
                        store.register(item, false)
                        line = "#{store.prefixString()} #{TxTimeCommitments::toString(item)}".yellow
                        puts line
                        vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    }
            end
        end

        if context then

            PolyActions::start(context)

            puts ""
            store.register(context, false)
            line = TxTimeCommitments::toString(context)
            if NxBallsService::isPresent(context["uuid"]) then
                line = "#{store.prefixString()} #{line} (#{NxBallsService::activityStringOrEmptyString("", context["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - 2

            nx79s = TxTimeCommitments::nx79s(context, 6)
            if nx79s.size > 0 then
                puts ""
                puts "Managed Items:".yellow
                vspaceleft = vspaceleft - 2
                nx79s
                    .map{|nx79|
                        {
                            "nx79" => nx79,
                            "rt"   => BankExtended::stdRecoveredDailyTimeInHours(nx79["item"]["uuid"])
                        }
                    }
                    .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
                    .each{|px|
                        nx79    = px["nx79"]
                        rt      = px["rt"]
                        element = nx79["item"]
                        PolyActions::dataPrefetchAttempt(element)
                        indx = store.register(element, false)
                        line = "#{store.prefixString()} (#{"%6.2f" % nx79["ordinal"]}) #{PolyFunctions::toString(element)} (rt: #{BankExtended::stdRecoveredDailyTimeInHours(element["uuid"]).round(2)})"
                        if NxBallsService::isPresent(element["uuid"]) then
                            line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", element["uuid"], "")})".green
                        end
                        puts line
                        vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    }
            end

            nx79s = TxTimeCommitments::nx79s(context, CommonUtils::screenHeight())
            if nx79s.size > 0 then
                puts ""
                puts "Tail (#{nx79s.size} items):".yellow
                vspaceleft = vspaceleft - 2
                nx79s
                    .each{|nx79|
                        element = nx79["item"]
                        PolyActions::dataPrefetchAttempt(element)
                        indx = store.register(element, false)
                        line = "#{store.prefixString()} (#{"%6.2f" % nx79["ordinal"]}) #{PolyFunctions::toString(element)}"
                        if NxBallsService::isPresent(element["uuid"]) then
                            line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", element["uuid"], "")})".green
                        end
                        puts line
                        vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                        break if vspaceleft <= 0
                    }
            end

            puts ""
            puts "commands: start <n> | access <n> | stop <n> | set ordinal <n> | ax39 | insert | exit".yellow

            input = LucilleCore::askQuestionAnswerAsString("> ")

            if input == "exit" then
                if LucilleCore::askQuestionAnswerAsBoolean("Stop time commitment ? ") then
                    PolyActions::stop(context)
                end
                CatalystListing::emptyContext()
                return
            end

            if input.start_with?("set ordinal")  then
                indx = input[1, 99].strip.to_i
                entity = store.get(indx)
                return if entity.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                TimeCommitmentMapping::link(context["uuid"], entity["uuid"], ordinal)
                return
            end

            if input == "ax39"  then
                ax39 = Ax39::interactivelyCreateNewAx()
                DxF1::setAttribute2(context["uuid"], "ax39",  ax39)
                return
            end

            if input == "insert" then
                type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "task"])
                return if type.nil?
                if type == "line" then
                    element = NxTasks::interactivelyIssueDescriptionOnlyOrNull()
                    return if element.nil?
                    ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                    TimeCommitmentMapping::link(context["uuid"], element["uuid"], ordinal)
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull(false)
                    return if element.nil?
                    ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                    TimeCommitmentMapping::link(context["uuid"], element["uuid"], ordinal)
                end
                return
            end

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                return if entity.nil?
                PolyPrograms::itemLanding(entity)
                return
            end

            CommandInterpreterDefault::run(input, store)

        else

            nxballs = NxBallsIO::nxballs()
            if nxballs.size > 0 then
                puts ""
                vspaceleft = vspaceleft - 1
                nxballs
                    .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
                    .each{|nxball|
                        store.register(nxball, false)
                        line = "#{store.prefixString()} [NxBall] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                        puts line.green
                        vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    }
            end

            puts ""
            vspaceleft = vspaceleft - 1

            CatalystListing::listingItems()
                .each{|item|
                    break if vspaceleft <= 0
                    store.register(item, true)
                    line = "#{store.prefixString()} #{PolyFunctions::toString(item)}"
                    if NxBallsService::isPresent(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            CommandInterpreterDefault::run(input, store)

        end
    end

    # PolyPrograms::itemLanding(item)
    def self.itemLanding(item)

        if item["mikuType"] == "fitness1" then
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            return nil
        end

        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = DxF1::getProtoItemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)
            entities = NetworkLinks::linkedEntities(item["uuid"])
            if entities.size > 0 then
                puts ""
                if entities.size < 200 then
                    entities
                        .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                        .each{|entity|
                            store.register(entity, false)
                            puts "#{store.prefixString()} #{PolyFunctions::toString(entity)}"
                        }
                else
                    puts "(... many entities, use `navigation` ...)"
                end
            end

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyPrograms::itemLanding(entity)
                next
            end

            CommandInterpreterDefault::run(input, store)
        }
    end
end
