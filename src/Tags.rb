
# encoding: UTF-8

class Tags

    # Tags::make(name_)
    def self.make(name_)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "287041db-39ac-464c-b557-2f172e721111",
            "unixtime" => Time.new.to_f,
            "name"     => name_
        }
    end

    # Tags::issue(name_)
    def self.issue(name_)
        set = Tags::make(name_)
        NyxObjects2::put(set)
        set
    end

    # Tags::issueSetInteractivelyOrNull()
    def self.issueSetInteractivelyOrNull()
        name_ = LucilleCore::askQuestionAnswerAsString("set name: ")
        return nil if name_ == ""
        Tags::issue(name_)
    end

    # Tags::toString(set)
    def self.toString(set)
        "[set] #{set["name"]}"
    end

    # Tags::tags()
    def self.sets()
        NyxObjects2::getSet("287041db-39ac-464c-b557-2f172e721111")
    end

    # Tags::landing(set)
    def self.landing(set)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(set["uuid"]).nil?

            puts Tags::toString(set).green
            puts "uuid: #{set["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            targets = Arrows::getTargetsForSource(set)
            targets = targets.select{|target| !NyxObjectInterface::isSet(target) }
            targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
            puts "" if !targets.empty?
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
                Tags::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = NGX15::issueNewNGX15InteractivelyOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(set, datapoint)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(set)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy tag".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy set: '#{Tags::toString(set)}': ") then
                    NyxObjects2::destroy(set)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Tags::tagsListing()
    def self.setsListing()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Tags::tags().each{|set|
                mx.item(
                    Tags::toString(set),
                    lambda { Tags::landing(set) }
                )
            }
            puts ""
            mx.item("Make new set".yellow, lambda { 
                i = Tags::issueSetInteractivelyOrNull()
                return if i.nil?
                Tags::landing(i)
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # ----------------------------------

    # Tags::nameIsUsed(name_)
    def self.nameIsUsed(name_)
        Tags::tags().any?{|set| set["name"].downcase == name_.downcase }
    end

    # Tags::selectExistingSetOrNull_v1()
    def self.selectExistingSetOrNull_v1()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("set", Tags::tags(), lambda { |set| Tags::toString(set) })
    end

    # Tags::pecoStyleSelectTagNameOrNull()
    def self.pecoStyleSelectTagNameOrNull()
        names = Tags::tags().map{|set| set["name"] }.sort

        # ---------------------------------------
        fragmentForPreselection = LucilleCore::askQuestionAnswerAsString("fragment for preselection: ")
        names = names.select{|name_| name_.downcase.include?(fragmentForPreselection.downcase) }.first(1000)
        # ---------------------------------------

        Miscellaneous::pecoStyleSelectionOrNull(names)
    end

    # Tags::selectTagByNameOrNull(name_)
    def self.selectTagByNameOrNull(name_)
        Tags::tags()
            .select{|set| set["name"].downcase == name_.downcase }
            .first
    end

    # Tags::selectExistingTagOrNull_v2()
    def self.selectExistingTagOrNull_v2()
        n = Tags::pecoStyleSelectTagNameOrNull()
        return nil if n.nil?
        Tags::selectTagByNameOrNull(n)
    end

    # Interface
    # Tags::selectExistingTagOrMakeNewOneOrNull()
    def self.selectExistingTagOrMakeNewOneOrNull()
        set = Tags::selectExistingTagOrNull_v2()
        return set if set
        if LucilleCore::askQuestionAnswerAsBoolean("Create a new set ? ") then
            loop {
                name_ = LucilleCore::askQuestionAnswerAsString("set name: ")
                if Tags::selectTagByNameOrNull(name_) then
                    return Tags::selectTagByNameOrNull(name_)
                end
                return Tags::issue(name_)
            }
        end
        nil
    end

    # ----------------------------------

    # Tags::mergeTwoTagsOfSameNameReturnTag(set1, set2)
    def self.mergeTwoTagsOfSameNameReturnTag(set1, set2)
        raise "4c54ea8b-7cb4-4838-98ed-66857bd22616" if ( set1["uuid"] == set2["uuid"] )
        raise "7d4b9f3e-9fe0-4594-a3c4-61d177a3a904" if ( set1["name"].downcase != set2["name"].downcase )
        set = Tags::issue(set1["name"])

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

    # Tags::redundancyPairOrNull()
    def self.redundancyPairOrNull()
        Tags::tags().combination(2).each{|set1, set2|
            next if set1["name"].downcase != set2["name"].downcase 
            return [set1, set2]
        }
        nil
    end

    # Interface
    # Tags::removeSetDuplicates()
    def self.removeSetDuplicates()
        while pair = Tags::redundancyPairOrNull() do
            set1, set2 = pair
            Tags::mergeTwoTagsOfSameNameReturnTag(set1, set2)
        end
    end

    # ----------------------------------

    # Tags::batchRename(oldname, newname)
    def self.batchRename(oldname, newname)
        Tags::tags()
            .each{|set|
                next if (set["name"] != oldname)
                set["name"] = newname
                NyxObjects2::put(set)
            }
    end
end
