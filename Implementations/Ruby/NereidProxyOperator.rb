
# encoding: UTF-8

class NereidProxyOperator

    # -------------------------------------------------------

    # NereidProxyOperator::elementMatchesIdentifier(element, identifier)
    def self.elementMatchesIdentifier(element, identifier)
        return true if element["description"] == identifier
    end

    # NereidProxyOperator::getElementsByIdentifier(identifier)
    def self.getElementsByIdentifier(identifier)
        NereidInterface::getElements()
            .select{|element| NereidProxyOperator::elementMatchesIdentifier(element, identifier) }
    end

    # NereidProxyOperator::selectElementOrNull()
    def self.selectElementOrNull()
        NyxUtils::selectOneOrNull(NereidInterface::getElements(), lambda{|element| NereidInterface::toString(element) })
    end

    # NereidProxyOperator::architectOrNull()
    def self.architectOrNull()
        system("clear")
        puts "NereidProxyOperator::architectOrNull()"
        LucilleCore::pressEnterToContinue()
        element = NereidProxyOperator::selectElementOrNull()
        return element if element
        NereidInterface::interactivelyIssueNewElementOrNull()
    end

    # NereidProxyOperator::nyxSearchItems()
    def self.nyxSearchItems()
        NereidInterface::getElements()
            .map{|element|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{NereidInterface::toString(element)}",
                    "type"         => "nereid",
                    "payload"      => element
                }
            }
    end

    # NereidProxyOperator::landing(element)
    def self.landing(element)

        locpaddingsize = 11

        loop {
            system("clear")
            element = NereidInterface::getElementOrNull(element["uuid"]) # could have been deleted or transmuted in the previous loop
            return if element.nil?

            puts "[nyx] #{NereidInterface::toString(element)}".green

            puts "uuid: #{element["uuid"]}".yellow
            puts "payload: #{element["payload"]}".yellow

            puts ""

            mx = LCoreMenuItemsNX1.new()

            NyxArrows::getParentsUUIDs(element["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx parent".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            NyxArrows::getChildrenUUIDs(element["uuid"]).each{|uuid1|
                e1 = Patricia::getDX7ByUUIDOrNull(uuid1)
                next if e1.nil?
                mx.item("#{"nyx child".ljust(locpaddingsize)}: #{Patricia::toString(e1)}", lambda { 
                    Patricia::landing(e1)
                })
            }

            puts ""

            mx.item("access".yellow, lambda { 
                Patricia::dx7access(element)
            })

            mx.item("update/set description".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                element["description"] = description
                NereidInterface::insertElement(element)
            })

            mx.item("patricia architect ; insert as parent".yellow, lambda { 
                Patricia::architectAddParentForDX7(element)
            })

            mx.item("patricia architect ; insert as child".yellow, lambda { 
                Patricia::architectAddChildForDX7(element)
            })

            mx.item("select and remove parent".yellow, lambda {
                Patricia::selectAndRemoveOneParentFromDX7(element)
            })

            mx.item("select and remove child".yellow, lambda {
                Patricia::selectAndRemoveOneChildFromDX7(element)
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
