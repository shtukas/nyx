
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

            puts Pages::toString(page).green

            mx = LCoreMenuItemsNX1.new()

            puts ""
            targets = Arrows::getTargetsForSource(page)
            targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
            targets
                .each{|object|
                    mx.item(
                        "|| #{NyxObjectInterface::toString(object)}",
                        lambda { NyxObjectInterface::landing(object) }
                    )
                }

            puts ""
            mx.item("rename page".yellow, lambda { 
                name_ = Miscellaneous::editTextSynchronously(page["name"]).strip
                return if name_ == ""
                page["name"] = name_
                NyxObjects2::put(page)
            })
            mx.item("Add datapoint".yellow, lambda { 
                    puts "To be implemented"
                    LucilleCore::pressEnterToContinue()
                }
            )
            mx.item("see json object".yellow, lambda { 
                puts JSON.pretty_generate(page)
                LucilleCore::pressEnterToContinue()
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

    # Pages::selectExistingPageOrNull()
    def self.selectExistingPageOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("page", Pages::pages(), lambda { |page| Pages::toString(page) })
    end

    # Pages::selectExistingPageOrMakeNewOneOrNull()
    def self.selectExistingPageOrMakeNewOneOrNull()
        page = Pages::selectExistingPageOrNull()
        return page if page
        if LucilleCore::askQuestionAnswerAsBoolean("Create a new page ? ") then
            loop {
                name_ = LucilleCore::askQuestionAnswerAsString("page name: ")
                if Pages::nameIsUsed(name_) then
                    puts "name '#{name_}' is already used"
                    next
                end
                return Pages::issue(name_)
            }
        end
        nil
    end
end
