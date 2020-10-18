
# encoding: UTF-8

class Sets

    # Sets::make(name_)
    def self.make(name_)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "287041db-39ac-464c-b557-2f172e721111",
            "unixtime" => Time.new.to_f,
            "name"     => name_
        }
    end

    # Sets::issue(name_)
    def self.issue(name_)
        set = Sets::make(name_)
        NyxObjects2::put(set)
        set
    end

    # Sets::issueSetInteractivelyOrNull()
    def self.issueSetInteractivelyOrNull()
        name_ = LucilleCore::askQuestionAnswerAsString("set name: ")
        return nil if name_ == ""
        Sets::issue(name_)
    end

    # Sets::toString(set)
    def self.toString(set)
        "[set] #{set["name"]}"
    end

    # Sets::sets()
    def self.sets()
        NyxObjects2::getSet("287041db-39ac-464c-b557-2f172e721111")
    end

    # Sets::landing(set)
    def self.landing(set)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(set["uuid"]).nil?

            puts Sets::toString(set).green
            puts "uuid: #{set["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            puts ""
            Arrows::getTargetForSourceOfGivenNyxType(set, "287041db-39ac-464c-b557-2f172e721111")
                .each{|s|
                    mx.item(
                        "linked: #{NyxObjectInterface::toString(s)}",
                        lambda { NyxObjectInterface::landing(s) }
                    )
                }

            puts ""
            targets = Arrows::getTargetsForSource(set)
            targets = targets.select{|target| !NyxObjectInterface::isSet(target) }
            targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
            targets
                .each{|object|
                    mx.item(
                        NyxObjectInterface::toString(object),
                        lambda { NyxObjectInterface::landing(object) }
                    )
                }

            puts ""
            mx.item("rename".yellow, lambda { 
                name_ = Miscellaneous::editTextSynchronously(set["name"]).strip
                return if name_ == ""
                set["name"] = name_
                NyxObjects2::put(set)
                Sets::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(set, datapoint)
            })
            mx.item("add to set".yellow, lambda { 
                s1 = Sets::selectExistingSetOrMakeNewOneOrNull()
                return if s1.nil?
                Arrows::issueOrException(s1, set)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(set)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy set".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy set: '#{Sets::toString(set)}': ") then
                    NyxObjects2::destroy(set)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Sets::setsListing()
    def self.setsListing()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Sets::sets().each{|set|
                mx.item(
                    Sets::toString(set),
                    lambda { Sets::landing(set) }
                )
            }
            puts ""
            mx.item("Make new set".yellow, lambda { 
                i = Sets::issueSetInteractivelyOrNull()
                return if i.nil?
                Sets::landing(i)
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # ----------------------------------

    # Sets::nameIsUsed(name_)
    def self.nameIsUsed(name_)
        Sets::sets().any?{|set| set["name"].downcase == name_.downcase }
    end

    # Sets::selectExistingSetOrNull_v1()
    def self.selectExistingSetOrNull_v1()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("set", Sets::sets(), lambda { |set| Sets::toString(set) })
    end

    # Sets::pecoStyleSelectSetNameOrNull()
    def self.pecoStyleSelectSetNameOrNull()
        names = Sets::sets().map{|set| set["name"] }.sort
        Miscellaneous::pecoStyleSelectionOrNull(names)
    end

    # Sets::selectSetByNameOrNull(name_)
    def self.selectSetByNameOrNull(name_)
        Sets::sets()
            .select{|set| set["name"].downcase == name_.downcase }
            .first
    end

    # Sets::selectExistingSetOrNull_v2()
    def self.selectExistingSetOrNull_v2()
        n = Sets::pecoStyleSelectSetNameOrNull()
        return nil if n.nil?
        Sets::selectSetByNameOrNull(n)
    end

    # Interface
    # Sets::selectExistingSetOrMakeNewOneOrNull()
    def self.selectExistingSetOrMakeNewOneOrNull()
        set = Sets::selectExistingSetOrNull_v2()
        return set if set
        if LucilleCore::askQuestionAnswerAsBoolean("Create a new set ? ") then
            loop {
                name_ = LucilleCore::askQuestionAnswerAsString("set name: ")
                if Sets::selectSetByNameOrNull(name_) then
                    return Sets::selectSetByNameOrNull(name_)
                end
                return Sets::issue(name_)
            }
        end
        nil
    end

    # ----------------------------------

    # Sets::mergeTwoSetsOfSameNameReturnSet(set1, set2)
    def self.mergeTwoSetsOfSameNameReturnSet(set1, set2)
        raise "4c54ea8b-7cb4-4838-98ed-66857bd22616" if ( set1["uuid"] == set2["uuid"] )
        raise "7d4b9f3e-9fe0-4594-a3c4-61d177a3a904" if ( set1["name"].downcase != set2["name"].downcase )
        set = Sets::issue(set1["name"])

        Arrows::getSourcesForTarget(set1).each{|source|
            Arrows::issueOrException(source, set)
        }
        Arrows::getTargetsForSource(set1).each{|target|
            Arrows::issueOrException(set, target)
        }

        Arrows::getSourcesForTarget(set2).each{|source|
            Arrows::issueOrException(source, set)
        }
        Arrows::getTargetsForSource(set2).each{|target|
            Arrows::issueOrException(set, target)
        }

        NyxObjects2::destroy(set1)
        NyxObjects2::destroy(set2)

        set
    end

    # Sets::redundancyPairOrNull()
    def self.redundancyPairOrNull()
        Sets::sets().combination(2).each{|set1, set2|
            next if set1["name"].downcase != set2["name"].downcase 
            return [set1, set2]
        }
        nil
    end

    # Interface
    # Sets::removeSetDuplicates()
    def self.removeSetDuplicates()
        while pair = Sets::redundancyPairOrNull() do
            set1, set2 = pair
            Sets::mergeTwoSetsOfSameNameReturnSet(set1, set2)
        end
    end

    # ----------------------------------

    # Sets::batchRename(oldname, newname)
    def self.batchRename(oldname, newname)
        Sets::sets()
            .each{|set|
                next if (set["name"] != oldname)
                set["name"] = newname
                NyxObjects2::put(set)
            }
    end
end
