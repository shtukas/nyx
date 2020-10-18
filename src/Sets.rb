
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
        page = Sets::make(name_)
        NyxObjects2::put(page)
        page
    end

    # Sets::issueSetInteractivelyOrNull()
    def self.issueSetInteractivelyOrNull()
        name_ = LucilleCore::askQuestionAnswerAsString("page name: ")
        return nil if name_ == ""
        Sets::issue(name_)
    end

    # Sets::toString(page)
    def self.toString(page)
        "[page] #{page["name"]}"
    end

    # Sets::pages()
    def self.pages()
        NyxObjects2::getSet("287041db-39ac-464c-b557-2f172e721111")
    end

    # Sets::landing(page)
    def self.landing(page)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(page["uuid"]).nil?

            puts Sets::toString(page).green
            puts "uuid: #{page["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            puts ""
            targets = Arrows::getTargetsForSource(page)
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
                name_ = Miscellaneous::editTextSynchronously(page["name"]).strip
                return if name_ == ""
                page["name"] = name_
                NyxObjects2::put(page)
                Sets::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(page, datapoint)
            })
            mx.item("add to page".yellow, lambda { 
                p1 = Sets::selectExistingSetOrMakeNewOneOrNull()
                return if p1.nil?
                Arrows::issueOrException(p1, page)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(page)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy page".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy page: '#{Sets::toString(page)}': ") then
                    NyxObjects2::destroy(page)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Sets::pagesListing()
    def self.pagesListing()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Sets::pages().each{|page|
                mx.item(
                    Sets::toString(page),
                    lambda { Sets::landing(page) }
                )
            }
            puts ""
            mx.item("Make new page".yellow, lambda { 
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
        Sets::pages().any?{|page| page["name"].downcase == name_.downcase }
    end

    # Sets::selectExistingSetOrNull_v1()
    def self.selectExistingSetOrNull_v1()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("page", Sets::pages(), lambda { |page| Sets::toString(page) })
    end

    # Sets::pecoStyleSelectSetNameOrNull()
    def self.pecoStyleSelectSetNameOrNull()
        names = Sets::pages().map{|page| page["name"] }.sort
        Miscellaneous::pecoStyleSelectionOrNull(names)
    end

    # Sets::selectSetByNameOrNull(name_)
    def self.selectSetByNameOrNull(name_)
        Sets::pages()
            .select{|page| page["name"].downcase == name_.downcase }
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
        page = Sets::selectExistingSetOrNull_v2()
        return page if page
        if LucilleCore::askQuestionAnswerAsBoolean("Create a new page ? ") then
            loop {
                name_ = LucilleCore::askQuestionAnswerAsString("page name: ")
                if Sets::selectSetByNameOrNull(name_) then
                    return Sets::selectSetByNameOrNull(name_)
                end
                return Sets::issue(name_)
            }
        end
        nil
    end

    # ----------------------------------

    # Sets::mergeTwoSetsOfSameNameReturnSet(page1, page2)
    def self.mergeTwoSetsOfSameNameReturnSet(page1, page2)
        raise "4c54ea8b-7cb4-4838-98ed-66857bd22616" if ( page1["uuid"] == page2["uuid"] )
        raise "7d4b9f3e-9fe0-4594-a3c4-61d177a3a904" if ( page1["name"].downcase != page2["name"].downcase )
        page = Sets::issue(page1["name"])

        Arrows::getSourcesForTarget(page1).each{|source|
            Arrows::issueOrException(source, page)
        }
        Arrows::getTargetsForSource(page1).each{|target|
            Arrows::issueOrException(page, target)
        }

        Arrows::getSourcesForTarget(page2).each{|source|
            Arrows::issueOrException(source, page)
        }
        Arrows::getTargetsForSource(page2).each{|target|
            Arrows::issueOrException(page, target)
        }

        NyxObjects2::destroy(page1)
        NyxObjects2::destroy(page2)

        page
    end

    # Sets::redundancyPairOrNull()
    def self.redundancyPairOrNull()
        Sets::pages().combination(2).each{|page1, page2|
            next if page1["name"].downcase != page2["name"].downcase 
            return [page1, page2]
        }
        nil
    end

    # Interface
    # Sets::removeSetDuplicates()
    def self.removeSetDuplicates()
        while pair = Sets::redundancyPairOrNull() do
            page1, page2 = pair
            Sets::mergeTwoSetsOfSameNameReturnSet(page1, page2)
        end
    end

    # ----------------------------------

    # Sets::batchRename(oldname, newname)
    def self.batchRename(oldname, newname)
        Sets::pages()
            .each{|page|
                next if (page["name"] != oldname)
                page["name"] = newname
                NyxObjects2::put(page)
            }
    end
end
