
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
        listing = OperationalListings::make(name1)
        NyxObjects2::put(listing)
        listing
    end

    # OperationalListings::issueListingInteractivelyOrNull()
    def self.issueListingInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("operational listing name: ")
        return nil if name1 == ""
        OperationalListings::issue(name1)
    end

    # OperationalListings::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("operational listing", OperationalListings::listings(), lambda{|l| OperationalListings::toString(l) })
    end

    # OperationalListings::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        listing = OperationalListings::selectOneExistingListingOrNull()
        return listing if listing
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no operational listing selected, create a new one ? ")
        OperationalListings::issueListingInteractivelyOrNull()
    end

    # OperationalListings::setTargetOrdinal(listing, target, ordinal)
    def self.setTargetOrdinal(listing, target, ordinal)
        KeyValueStore::set(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{listing["uuid"]}:#{target["uuid"]}", ordinal)
    end

    # OperationalListings::getTargetOrdinal(listing, target)
    def self.getTargetOrdinal(listing, target)
        ordinal = KeyValueStore::getOrNull(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{listing["uuid"]}:#{target["uuid"]}")
        if ordinal then
            return ordinal.to_f
        end
        ordinals = Arrows::getTargetsForSource(listing)
                    .map{|t| KeyValueStore::getOrNull(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{listing["uuid"]}:#{t["uuid"]}") }
                    .compact
                    .map{|o| o.to_f }
        ordinal = ([0] + ordinals).max + 1
        KeyValueStore::set(nil, "60d47387-cdd4-44f1-a334-904c2b7c4b5c:#{listing["uuid"]}:#{target["uuid"]}", ordinal)
        ordinal
    end

    # OperationalListings::toString(listing)
    def self.toString(listing)
        "[operational listing] #{listing["name"]}"
    end

    # OperationalListings::listingToCatalystObjects(listing, basemetric, asteroidBankAccountId, asteroidDailyTimeCommitmentNumbers, asteroidDailyTimeExpectationInHours)
    def self.listingToCatalystObjects(listing, basemetric, asteroidBankAccountId, asteroidDailyTimeCommitmentNumbers, asteroidDailyTimeExpectationInHours)

        itemMetric = lambda { |isRunning, itemuuid, asteroidDailyTimeExpectationInHours, itemIndex, basemetric|
            if isRunning then
                1
            else
                if BankExtended::multiTaskingTopWithGeometricProgressionShouldShowItem(itemuuid, asteroidDailyTimeExpectationInHours, itemIndex) then
                    basemetric - itemIndex.to_f/100
                else
                    0
                end
            end
        }

        open1 = lambda {|object|
            if GenericNyxObject::isNGX15(object) then
                NGX15::openNGX15(object)
                return
            end
            if GenericNyxObject::isQuark(object) then
                Quarks::open1(object)
                return
            end
            puts GenericNyxObject::toString(object)
            raise "741252ae-c6bf-4663-9cbf-2256b97ffd66"
        }

        itemIndex = -1
        Arrows::getTargetsForSource(listing)
            .sort{|t1, t2| OperationalListings::getTargetOrdinal(listing, t1) <=> OperationalListings::getTargetOrdinal(listing, t2) }
            .map{|target|
                uuid = "b7185097-dc3e-43cc-b573-676b411e1a44:#{listing["uuid"]}:#{target["uuid"]}"
                isRunning = Runner::isRunning?(uuid)
                itemIndex = itemIndex + 1
                metric = itemMetric.call(isRunning, uuid, asteroidDailyTimeExpectationInHours, itemIndex, basemetric)
                body = "#{OperationalListings::toString(listing)} #{GenericNyxObject::toString(target)}#{asteroidDailyTimeCommitmentNumbers} (item daily time: #{BankExtended::recoveredDailyTimeInHours(uuid).round(2)} hours)#{isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)" : ""}"
                {
                    "uuid"             => uuid,
                    "body"             => body,
                    "metric"           => metric,
                    "landing"          => lambda { GenericNyxObject::landing(target) },
                    "nextNaturalStep"  => lambda { 
                        if isRunning then
                            timespan = Runner::stop(uuid)
                            puts "Adding #{timespan.round(2)} seconds to item '#{body}'"
                            Bank::put(uuid, timespan)
                            puts "Adding #{timespan.round(2)} seconds to asteroidBankAccountId: #{asteroidBankAccountId}"
                            Bank::put(asteroidBankAccountId, timespan)
                            if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ", false) then
                                GenericNyxObject::destroy(target)
                            end
                        else
                            Runner::start(uuid)
                            open1.call(target)
                            if !LucilleCore::askQuestionAnswerAsBoolean("keep running ? ", true) then
                                timespan = Runner::stop(uuid)
                                puts "Adding #{timespan.round(2)} seconds to item '#{body}'"
                                Bank::put(uuid, timespan)
                                puts "Adding #{timespan.round(2)} seconds to asteroidBankAccountId: #{asteroidBankAccountId}"
                                Bank::put(asteroidBankAccountId, timespan)
                                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
                                    GenericNyxObject::destroy(target)
                                end
                            end
                        end
                    },
                    "isRunning"        => isRunning,
                    "isRunningForLong" => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600,
                    "x-metadata-1113"  => {
                        "basemetric" => basemetric,
                        "asteroidBankAccountId" => asteroidBankAccountId,
                        "asteroidDailyTimeCommitmentNumbers" => asteroidDailyTimeCommitmentNumbers,
                        "asteroidDailyTimeExpectationInHours" => asteroidDailyTimeExpectationInHours,
                        "uuid" => uuid,
                        "isRunning" => isRunning,
                        "itemIndex" => itemIndex,
                        "metric" => metric
                    }
                }
            }
    end

    # OperationalListings::getListingTargetsInOrdinalOrder(listing)
    def self.getListingTargetsInOrdinalOrder(listing)
        Arrows::getTargetsForSource(listing)
            .sort{|t1, t2| OperationalListings::getTargetOrdinal(listing, t1) <=> OperationalListings::getTargetOrdinal(listing, t2) }
    end

    # OperationalListings::landing(listing)
    def self.landing(listing)
        loop {
            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts OperationalListings::toString(listing).green
            puts "uuid: #{listing["uuid"]}".yellow

            sources = Arrows::getSourcesForTarget(listing)
            puts "" if !sources.empty?
            sources.each{|source|
                mx.item(
                    "source: #{GenericNyxObject::toString(source)}",
                    lambda { GenericNyxObject::landing(source) }
                )
            }

            targets = OperationalListings::getListingTargetsInOrdinalOrder(listing)

            puts "" if !targets.empty?
            targets
                .each{|target|
                    mx.item(
                        "target ( #{"%6.3f" % OperationalListings::getTargetOrdinal(listing, target)} ) #{GenericNyxObject::toString(target)}",
                        lambda { GenericNyxObject::landing(target) }
                    )
                }

            puts ""

            mx.item("rename".yellow, lambda { 
                name1 = Miscellaneous::editTextSynchronously(listing["name"]).strip
                return if name1 == ""
                listing["name"] = name1
                NyxObjects2::put(listing)
                OperationalListings::removeSetDuplicates()
            })

            mx.item("make datapoint ; insert at ordinal".yellow, lambda { 
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(listing, datapoint)
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                OperationalListings::setTargetOrdinal(listing, datapoint, ordinal)
            })

            mx.item("select object ; add at ordinal".yellow, lambda { 
                o = Patricia::searchAndReturnObjectOrNullSequential()
                return if o.nil?
                Arrows::issueOrException(listing, o)
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                OperationalListings::setTargetOrdinal(listing, o, ordinal)
            })

            mx.item("set target ordinal".yellow, lambda { 
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", OperationalListings::getListingTargetsInOrdinalOrder(listing), lambda{|t| GenericNyxObject::toString(t) })
                return if target.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                OperationalListings::setTargetOrdinal(listing, target, ordinal)
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(listing)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy listing".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy operational listing: '#{OperationalListings::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # OperationalListings::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("operational listings dive",lambda { 
                loop {
                    listings = OperationalListings::listings()
                    listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("operational listing", listings, lambda{|l| OperationalListings::toString(l) })
                    return if listing.nil?
                    OperationalListings::landing(listing)
                }
            })

            ms.item("make new operational listing",lambda { OperationalListings::issueListingInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
