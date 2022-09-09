
class PolyPrograms

    # PolyPrograms::catalystMainListing()
    def self.catalystMainListing()
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

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
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        vspaceleft = vspaceleft - 1

        tops = TopLevel::items()
        tops.each{|item|
            store.register(item, false)
            line = "#{store.prefixString()} #{PolyFunctions::toString(item)}".yellow
            if NxBallsService::isPresent(item["uuid"]) then
                line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
        }
        puts ""
        vspaceleft = vspaceleft - 1

        listingItems = CatalystListing::listingItems()

        displayedOneNxBall = false
        NxBallsIO::nxballs()
            .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
            .each{|nxball|
                displayedOneNxBall = true
                store.register(nxball, false)
                line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                puts line.green
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }
        if displayedOneNxBall then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        inbox = InboxItems::listingItems()
        inbox.each{|item|
            store.register(item, false)
            line = "#{store.prefixString()} #{PolyFunctions::toString(item)}"
            if NxBallsService::isPresent(item["uuid"]) then
                line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
        }
        if !inbox.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
        end

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

        CommandInterpreterDefault::commandPrompt(store)
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

    # PolyPrograms::timeCommitmentProgram(item)
    def self.timeCommitmentProgram(item)
        PolyActions::start(item)

        loop {
            system("clear")

            store = ItemStore.new()

            store.register(item, false)
            puts "#{store.prefixString()} #{TxTimeCommitmentProjects::toString(item)} #{NxBallsService::activityStringOrEmptyString("(", item["uuid"], ")")}".green

            nx79s = TxTimeCommitmentProjects::nx79s(item, 6)
            if nx79s.size > 0 then
                puts ""
                puts "Managed Items:"
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
                    }
            end

            nx79s = TxTimeCommitmentProjects::nx79s(item, CommonUtils::screenHeight()-20)
            if nx79s.size > 0 then
                puts ""
                puts "Tail (#{nx79s.size} items):"
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
                    }
            end

            puts ""
            puts "commands: start <n> | access <n> | stop <n> | set ordinal <n> | ax39 | insert | exit".yellow

            input = LucilleCore::askQuestionAnswerAsString("> ")

            break if input == "exit"

            if input.start_with?("set ordinal")  then
                indx = input[1, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                OwnerItemsMapping::link(item["uuid"], entity["uuid"], ordinal)
                next
            end

            if input == "ax39"  then
                ax39 = Ax39::interactivelyCreateNewAx()
                DxF1::setAttribute2(item["uuid"], "ax39",  ax39)
                break
            end

            if input == "insert" then
                type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "task"])
                next if type.nil?
                if type == "line" then
                    element = NxTasks::interactivelyIssueDescriptionOnlyOrNull()
                    next if element.nil?
                    ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                    OwnerItemsMapping::link(item["uuid"], element["uuid"], ordinal)
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull(false)
                    next if element.nil?
                    ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                    OwnerItemsMapping::link(item["uuid"], element["uuid"], ordinal)
                end
                next
            end

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyPrograms::itemLanding(entity)
                next
            end

            CommandInterpreterDefault::run(input, store)
        }

        if NxBallsService::isRunning(item["uuid"]) then
            if LucilleCore::askQuestionAnswerAsBoolean("Continue time commiment ? ") then

            else
                NxBallsService::close(item["uuid"], true)
            end
        end
    end
end
