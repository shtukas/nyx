
class PolyPrograms

    # PolyPrograms::catalystMainListing()
    def self.catalystMainListing()

        system("clear")

        context = CatalystListing::getContextOrNull()

        vspaceleft = CommonUtils::screenHeight() - (context ? 5 : 4)

        vspaceleft =  vspaceleft - CommonUtils::verticalSize(CommandInterpreters::catalystListingCommands())

        if context.nil? then
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
        else
            puts ""
            puts "🚀 Time Commitment 🚀"
            vspaceleft = vspaceleft - 2
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
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

            nx79s = TxTimeCommitments::nx79s(context, CommonUtils::screenHeight())
            if nx79s.size > 0 then
                puts ""
                vspaceleft = vspaceleft - 1
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
            puts CommandInterpreters::catalystListingCommands().yellow
            puts "commands: set ordinal <n> | ax39 | insert | detach <n> | exit".yellow

            input = LucilleCore::askQuestionAnswerAsString("> ")

            if input == "exit" then
                if LucilleCore::askQuestionAnswerAsBoolean("You are exiting context. Stop NxBall ? ", true) then
                    PolyActions::stop(context)
                end
                CatalystListing::emptyContext()
                return
            end

            if input == "stop 0" then
                NxBallsService::pause(context["uuid"])
                return
            end

            if input.start_with?("set ordinal")  then
                indx = input[11, 99].strip.to_i
                entity = store.get(indx)
                return if entity.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                TimeCommitmentMapping::link(context["uuid"], entity["uuid"], ordinal)
                return
            end

            if input.start_with?("detach")  then
                indx = input[6, 99].strip.to_i
                entity = store.get(indx)
                return if entity.nil?
                TimeCommitmentMapping::unlink(context["uuid"], entity["uuid"])
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

            puts ""
            CommandInterpreters::catalystListing(input, store)

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
            puts CommandInterpreters::catalystListingCommands().yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            CommandInterpreters::catalystListing(input, store)
        end
    end

    # PolyPrograms::itemLanding(item)
    def self.itemLanding(item)
        if item["mikuType"] == "fitness1" then
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::landing(item)
            return
        end

        if item["mikuType"] == "TxTimeCommitment" then
            TxTimeCommitments::landing(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::landing(item)
            return
        end

        if item["mikuType"] == "TxDated" then
            TxDateds::landing(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            NxTasks::landing(item)
            return
        end

        if item["mikuType"] == "NyxNode" then
            NyxNodes::landing(item)
            return
        end

        raise "(error: D9DD0C7C-ECC4-46D0-A1ED-CD73591CC87B): item: #{item}"
    end
end
