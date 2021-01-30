
# encoding: UTF-8

class Quarks

    # Quarks::quarks()
    def self.quarks()
        NSCoreObjects::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
    end

    # Quarks::issueNewQuarkInteractivelyOrNull()
    def self.issueNewQuarkInteractivelyOrNull()
        element = NereidInterface::interactivelyIssueNewElementOrNull()
        return nil if element.nil?
        quark = {
            "uuid"       => SecureRandom.hex,
            "nyxNxSet"   => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"   => Time.new.to_i,
            "nereiduuid" => element["uuid"]
        }
        NSCoreObjects::put(quark)
        NereidInterface::setOwnership(element["uuid"], "catalyst")
        quark
    end

    # --------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        "[quark] #{NereidInterface::toString(quark["nereiduuid"])}"
    end

    # --------------------------------------------------

    # Quarks::access(quark)
    def self.access(quark)
        NereidInterface::access(quark["nereiduuid"])
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if NSCoreObjects::getOrNull(quark["uuid"]).nil?
            quark = NSCoreObjects::getOrNull(quark["uuid"]) # could have been transmuted in the previous loop

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow
            puts "ordinal: #{Ordinals::getObjectOrdinal(quark)}".yellow

            puts ""

            Arrows::getSourcesForTarget(quark).each{|source|
                mx.item(
                    "source: #{Patricia::toString(source)}",
                    lambda { Patricia::landing(source) }
                )
            }

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quarks::access(quark) }
            )

            mx.item("set/update ordinal".yellow, lambda {
                ordinal = LucilleCore::askQuestionAnswerAsString("ordnal: ")
                return if ordinal == ""
                Ordinals::setOrdinalForUUID(quark["uuid"], ordinal.to_f)
            })

            mx.item("move to another DxThread".yellow, lambda {
                parents = Arrows::getSourcesForTarget(quark)
                if parents.size == 0 then
                    Patricia::moveTargetToNewDxThread(quark, nil)
                    return
                end
                if parents.size == 1 then
                    Patricia::moveTargetToNewDxThread(quark, parents[0])
                    return
                end
                parent = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda { |target| Patricia::toString(target) })
                return if parent.nil?
                Patricia::moveTargetToNewDxThread(quark, parent)
            })

            mx.item("edit".yellow, lambda {
                NereidInterface::edit(quark["nereiduuid"])
            })

            mx.item("transmute".yellow, lambda { 
                NereidInterface::transmuteOrNull(quark["nereiduuid"])
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(quark)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy quark and content".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this quark and its content? ") then
                    Quarks::destroyQuarkAndNereidContent(quark)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Quarks::destroyQuark(quark)
    def self.destroyQuark(quark)
        NSCoreObjects::destroy(quark)
    end

    # Quarks::destroyQuarkAndNereidContent(quark)
    def self.destroyQuarkAndNereidContent(quark)
        status = NereidInterface::destroyElement(quark["nereiduuid"])
        return if !status
        NSCoreObjects::destroy(quark)
    end
end
