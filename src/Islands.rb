
# encoding: UTF-8

class Islands

    # Islands::make(name_)
    def self.make(name_)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "287041db-39ac-464c-b557-2f172e721111",
            "unixtime" => Time.new.to_f,
            "name"     => name_
        }
    end

    # Islands::issue(name_)
    def self.issue(name_)
        island = Islands::make(name_)
        NyxObjects2::put(island)
        island
    end

    # Islands::issueIslandInteractivelyOrNull()
    def self.issueIslandInteractivelyOrNull()
        name_ = LucilleCore::askQuestionAnswerAsString("island name: ")
        return nil if name_ == ""
        Islands::issue(name_)
    end

    # Islands::toString(island)
    def self.toString(island)
        "[island] #{island["name"]}"
    end

    # Islands::islands()
    def self.islands()
        NyxObjects2::getSet("287041db-39ac-464c-b557-2f172e721111")
    end

    # Islands::landing(island)
    def self.landing(island)
        loop {
            system("clear")

            puts Islands::toString(island).green

            mx = LCoreMenuItemsNX1.new()

            puts ""
            Links::getLinkedObjectsForCenter(island).each{|i|
                mx.item(
                    "-> #{Islands::toString(i)}",
                    lambda { Islands::landing(i) }
                )
            }

            puts ""
            targets = Arrows::getTargetsForSource(island)
            targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
            targets
                .each{|object|
                    mx.item(
                        "|| #{NyxObjectInterface::toString(object)}",
                        lambda { NyxObjectInterface::landing(object) }
                    )
                }

            puts ""
            mx.item("rename island".yellow, lambda { 
                name_ = Miscellaneous::editTextSynchronously(island["name"]).strip
                return if name_ == ""
                island["name"] = name_
                NyxObjects2::put(island)
            })
            mx.item("Make new link".yellow, lambda { 
                i = Islands::selectExistingIslandOrMakeNewOneOrNull()
                return if i.nil?
                Links::issueOrException(island, i)
            })
            mx.item("Add datapoint".yellow, lambda { 
                    puts "To be implemented"
                    LucilleCore::pressEnterToContinue()
                }
            )
            mx.item("see json object".yellow, lambda { 
                puts JSON.pretty_generate(island)
                LucilleCore::pressEnterToContinue()
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Islands::islandsListing()
    def self.islandsListing()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Islands::islands().each{|island|
                mx.item(
                    Islands::toString(island),
                    lambda { Islands::landing(island) }
                )
            }
            puts ""
            mx.item("Make new island".yellow, lambda { 
                i = Islands::issueIslandInteractivelyOrNull()
                return if i.nil?
                Islands::landing(i)
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # ----------------------------------

    # Islands::nameIsUsed(name_)
    def self.nameIsUsed(name_)
        Islands::islands().any?{|island| island["name"].downcase == name_.downcase }
    end

    # Islands::selectExistingIslandOrNull()
    def self.selectExistingIslandOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("island", Islands::islands(), lambda { |island| Islands::toString(island) })
    end

    # Islands::selectExistingIslandOrMakeNewOneOrNull()
    def self.selectExistingIslandOrMakeNewOneOrNull()
        island = Islands::selectExistingIslandOrNull()
        return island if island
        if LucilleCore::askQuestionAnswerAsBoolean("Create a new island ? ") then
            loop {
                name_ = LucilleCore::askQuestionAnswerAsString("island name: ")
                if Islands::nameIsUsed(name_) then
                    puts "name '#{name_}' is already used"
                    next
                end
                return Islands::issue(name_)
            }
        end
        nil
    end
end
