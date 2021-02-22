
# encoding: UTF-8

class M92

    # This class exists to allow Nereid Elements to be landed on as elements on the Nyx ecosystem, and not as native Nereid elements

    # -------------------------------------------------------

    # M92::elementMatchesIdentifier(element, identifier)
    def self.elementMatchesIdentifier(element, identifier)
        return true if element["description"] == identifier
    end

    # M92::getElementsByIdentifier(identifier)
    def self.getElementsByIdentifier(identifier)
        NereidInterface::getElements()
            .select{|element| M92::elementMatchesIdentifier(element, identifier) }
    end

    # M92::selectElementOrNull()
    def self.selectElementOrNull()
        CatalystUtils::selectOneOrNull(NereidInterface::getElements(), lambda{|element| NereidInterface::toString(element) })
    end

    # M92::architectNodeOrNull()
    def self.architectNodeOrNull()
        system("clear")
        puts "M92::architectNodeOrNull()"
        LucilleCore::pressEnterToContinue()
        element = M92::selectElementOrNull()
        return element if element
        NereidInterface::interactivelyIssueNewElementOrNull()
    end

    # M92::nyxSearchItems()
    def self.nyxSearchItems()
        NereidInterface::getElements()
            .map{|element|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{NereidInterface::toString(element)}",
                    "payload"      => element
                }
            }
    end

    # M92::landing(element)
    def self.landing(element)

        loop {
            system("clear")
            element = NereidInterface::getElementOrNull(element["uuid"]) # could have been deleted or transmuted in the previous loop
            return if element.nil?

            puts "[nyx] #{NereidInterface::toString(element)}".green

            puts "uuid: #{element["uuid"]}".yellow
            puts "payload: #{element["payload"]}".yellow

            puts ""

            mx = LCoreMenuItemsNX1.new()

            Network::getLinkedObjects(element).each{|node|
                mx.item("related: #{Patricia::toString(node)}", lambda { 
                    Patricia::landing(node)
                })
            }

            puts ""

            mx.item("access".yellow, lambda { 
                NereidInterface::access(element)
            })

            mx.item("update/set description".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                element["description"] = description
                NereidInterface::insertElement(element)
            })

            mx.item("link to network architected".yellow, lambda { 
                Patricia::linkToArchitectedNode(element)
            })

            mx.item("select and remove related".yellow, lambda {
                Patricia::selectAndRemoveLinkedNode(element)
            })

            mx.item("transmute".yellow, lambda { 
                NereidInterface::transmuteOrNull(element)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    NereidInterface::destroyElement(element["uuid"])
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

end
