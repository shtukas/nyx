
# encoding: UTF-8

class Pages

    # Pages::make(name_)
    def self.make(name_)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "287041db-39ac-464c-b557-2f172e721111",
            "unixtime" => Time.new.to_f,
            "name"     => name_
        }
    end

    # Pages::issue(name_)
    def self.issue(name_)
        page = Pages::make(name_)
        NyxObjects2::put(page)
        page
    end

    # Pages::issuePageInteractivelyOrNull()
    def self.issuePageInteractivelyOrNull()
        name_ = LucilleCore::askQuestionAnswerAsString("page name: ")
        return nil if name_ == ""
        Pages::issue(name_)
    end

    # Pages::toString(page)
    def self.toString(page)
        "[page] #{page["name"]}"
    end

    # Pages::pages()
    def self.pages()
        NyxObjects2::getSet("287041db-39ac-464c-b557-2f172e721111")
    end

    # Pages::landing(page)
    def self.landing(page)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(page["uuid"]).nil?

            puts Pages::toString(page).green
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
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(page, datapoint)
            })
            mx.item("add to page".yellow, lambda { 
                p1 = Pages::selectExistingPageOrMakeNewOneOrNull()
                return if p1.nil?
                Arrows::issueOrException(p1, page)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(page)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy page".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy page: '#{Pages::toString(page)}': ") then
                    NyxObjects2::destroy(page)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Pages::pagesListing()
    def self.pagesListing()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Pages::pages().each{|page|
                mx.item(
                    Pages::toString(page),
                    lambda { Pages::landing(page) }
                )
            }
            puts ""
            mx.item("Make new page".yellow, lambda { 
                i = Pages::issuePageInteractivelyOrNull()
                return if i.nil?
                Pages::landing(i)
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # ----------------------------------

    # Pages::nameIsUsed(name_)
    def self.nameIsUsed(name_)
        Pages::pages().any?{|page| page["name"].downcase == name_.downcase }
    end

    # Pages::selectExistingPageOrNull_v1()
    def self.selectExistingPageOrNull_v1()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("page", Pages::pages(), lambda { |page| Pages::toString(page) })
    end

    # Pages::pecoStyleSelectPageNameOrNull()
    def self.pecoStyleSelectPageNameOrNull()
        names = Pages::pages().map{|page| page["name"] }.sort
        Miscellaneous::pecoStyleSelectionOrNull(names)
    end

    # Pages::selectPageByNameOrNull(name_)
    def self.selectPageByNameOrNull(name_)
        Pages::pages()
            .select{|page| page["name"].downcase == name_.downcase }
            .first
    end

    # Pages::selectExistingPageOrNull_v2()
    def self.selectExistingPageOrNull_v2()
        n = Pages::pecoStyleSelectPageNameOrNull()
        return nil if n.nil?
        Pages::selectPageByNameOrNull(n)
    end

    # Pages::selectExistingPageOrMakeNewOneOrNull()
    def self.selectExistingPageOrMakeNewOneOrNull()
        page = Pages::selectExistingPageOrNull_v2()
        return page if page
        if LucilleCore::askQuestionAnswerAsBoolean("Create a new page ? ") then
            loop {
                name_ = LucilleCore::askQuestionAnswerAsString("page name: ")
                if Pages::selectPageByNameOrNull(name_) then
                    return Pages::selectPageByNameOrNull(name_)
                end
                return Pages::issue(name_)
            }
        end
        nil
    end

    # ----------------------------------

    # Pages::mergeTwoPagesOfSameNameReturnPage(page1, page2)
    def self.mergeTwoPagesOfSameNameReturnPage(page1, page2)
        raise "4c54ea8b-7cb4-4838-98ed-66857bd22616" if ( page1["uuid"] == page2["uuid"] )
        raise "7d4b9f3e-9fe0-4594-a3c4-61d177a3a904" if ( page1["name"].downcase != page2["name"].downcase )
        page = Pages::issue(page1["name"])

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

    # Pages::redundancyPairOrNull()
    def self.redundancyPairOrNull()
        Pages::pages().combination(2).each{|page1, page2|
            next if page1["name"].downcase != page2["name"].downcase 
            return [page1, page2]
        }
        nil
    end

    # Pages::removePageDuplicates()
    def self.removePageDuplicates()
        while pair = Pages::redundancyPairOrNull() do
            page1, page2 = pair
            Pages::mergeTwoPagesOfSameNameReturnPage(page1, page2)
        end
    end

end
