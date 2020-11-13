
# encoding: UTF-8

class OperationalListings

    # OperationalListings::listings()
    def self.listings()
        NyxObjects2::getSet("abb20581-f020-43e1-9c37-6c3ef343d2f5")
    end

    # OperationalListings::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "abb20581-f020-43e1-9c37-6c3ef343d2f5",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # OperationalListings::issue(name1)
    def self.issue(name1)
        node = OperationalListings::make(name1)
        NyxObjects2::put(node)
        node
    end

    # OperationalListings::issueListingInteractivelyOrNull()
    def self.issueListingInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("ops node name: ")
        return nil if name1 == ""
        OperationalListings::issue(name1)
    end

    # OperationalListings::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("ops node", OperationalListings::listings(), lambda{|node| OperationalListings::toString(node) })
    end

    # OperationalListings::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        node = OperationalListings::selectOneExistingListingOrNull()
        return node if node
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no ops node selected, create a new one ? ")
        OperationalListings::issueListingInteractivelyOrNull()
    end

    # OperationalListings::setTargetOrdinal(node, target, ordinal)
    def self.setTargetOrdinal(node, target, ordinal)
        KeyValueStore::set(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{node["uuid"]}:#{target["uuid"]}", ordinal)
    end

    # OperationalListings::getTargetOrdinal(node, target)
    def self.getTargetOrdinal(node, target)
        ordinal = KeyValueStore::getOrNull(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{node["uuid"]}:#{target["uuid"]}")
        if ordinal then
            return ordinal.to_f
        end
        ordinals = Arrows::getTargetsForSource(node)
                    .map{|t| KeyValueStore::getOrNull(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{node["uuid"]}:#{t["uuid"]}") }
                    .compact
                    .map{|o| o.to_f }
        ordinal = ([0] + ordinals).max + 1
        KeyValueStore::set(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{node["uuid"]}:#{target["uuid"]}", ordinal)
        ordinal
    end

    # OperationalListings::toString(node)
    def self.toString(node)
        "[ops node] #{node["name"]}"
    end

    # OperationalListings::listingToCatalystObjects(node, basemetric, asteroidBankAccountId, asteroidMetadata)
    def self.listingToCatalystObjects(node, basemetric, asteroidBankAccountId, asteroidMetadata)
        counter = -1
        Arrows::getTargetsForSource(node)
            .sort{|t1, t2| OperationalListings::getTargetOrdinal(node, t1) <=> OperationalListings::getTargetOrdinal(node, t2) }
            .map{|target|
                uuid = "b7185097-dc3e-43cc-b573-676b411e1a44:#{node["uuid"]}:#{target["uuid"]}"
                isRunning = Runner::isRunning?(uuid)
                counter = counter + 1
                {
                    "uuid"             => uuid,
                    "body"             => "#{OperationalListings::toString(node)} #{GenericNyxObject::toString(target)} #{asteroidMetadata}",
                    "metric"           => basemetric - counter.to_f/100,
                    "landing"          => lambda { GenericNyxObject::landing(target) },
                    "nextNaturalStep"  => lambda { 
                        if isRunning then
                            timespan = Runner::stop(uuid)
                            # We do not put the time in the item's own bank account, we put it into the asteroid's bank account
                            Bank::put(asteroidBankAccountId, timespan)
                        else
                            Runner::start(uuid)
                            GenericNyxObject::landing(target)
                            if !LucilleCore::askQuestionAnswerAsBoolean("keep running ? ") then
                                timespan = Runner::stop(uuid)
                                # We do not put the time in the item's own bank account, we put it into the asteroid's bank account
                                Bank::put(asteroidBankAccountId, timespan)
                            end
                        end
                    },
                    "isRunning"        => isRunning,
                    "isRunningForLong" => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600
                }
            }
    end

    # OperationalListings::getListingTargetsInOrdinalOrder(node)
    def self.getListingTargetsInOrdinalOrder(node)
        Arrows::getTargetsForSource(node)
            .sort{|t1, t2| OperationalListings::getTargetOrdinal(node, t1) <=> OperationalListings::getTargetOrdinal(node, t2) }
    end

    # OperationalListings::landing(node)
    def self.landing(node)

        mx = LCoreMenuItemsNX2.new()

        lambdaDisplay = lambda {

            node = NyxObjects2::getOrNull(node["uuid"])

            mx.reset()

            puts OperationalListings::toString(node).green
            puts "uuid: #{node["uuid"]}".yellow

            sources = Arrows::getSourcesForTarget(node)
            puts "" if !sources.empty?
            sources.each{|source|
                mx.item(
                    "source: #{GenericNyxObject::toString(source)}",
                    lambda { GenericNyxObject::landing(source) }
                )
            }

            targets = OperationalListings::getListingTargetsInOrdinalOrder(node)
            puts "" if !targets.empty?
            targets
                .each{|target|
                    mx.item(
                        "target ( #{"%6.3f" % OperationalListings::getTargetOrdinal(node, target)} ) #{GenericNyxObject::toString(target)}",
                        lambda { GenericNyxObject::landing(target) }
                    )
                }

        }

        lambdaHelpDisplay = lambda {
            [
                "-> rename",
                "-> insert datapoint at ordinal",
                "-> set target ordinal",
                "-> json object",
                "-> destroy node"
            ].join("\n")
        }

        lambdaPromptInterpreter = lambda { |command|

            node = NyxObjects2::getOrNull(node["uuid"])

            if Miscellaneous::isInteger(command) then
                mx.executeFunctionAtPositionGetValueOrNull(command.to_i)
                return
            end

            if command == "rename" then
                name1 = Miscellaneous::editTextSynchronously(node["name"]).strip
                return if name1 == ""
                node["name"] = name1
                NyxObjects2::put(node)
                OperationalListings::removeSetDuplicates()
                return
            end

            if command == "insert datapoint at ordinal" then
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(node, datapoint)
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                OperationalListings::setTargetOrdinal(node, datapoint, ordinal)
                return
            end

            if command == "set target ordinal" then
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", OperationalListings::getListingTargetsInOrdinalOrder(node), lambda{|t| GenericNyxObject::toString(t) })
                return if target.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                OperationalListings::setTargetOrdinal(node, target, ordinal)
                return
            end

            if command == "json object" then
                puts JSON.pretty_generate(node)
                LucilleCore::pressEnterToContinue()
                return
            end

            if command == "destroy node" then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy ops node: '#{OperationalListings::toString(node)}': ") then
                    NyxObjects2::destroy(node)
                end
                return
            end
        }

        lambdaStillGoing = lambda {
            !NyxObjects2::getOrNull(node["uuid"]).nil?
        }

        ProgramNx::Nx01(lambdaDisplay, lambdaHelpDisplay, lambdaPromptInterpreter, lambdaStillGoing)
    end

    # OperationalListings::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("ops nodes dive",lambda { 
                loop {
                    nodes = OperationalListings::listings()
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("ops node", nodes, lambda{|node| OperationalListings::toString(node) })
                    return if node.nil?
                    OperationalListings::landing(node)
                }
            })

            ms.item("make new ops node",lambda { OperationalListings::issueListingInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
