
# encoding: UTF-8

class Quarks

    # Quarks::quarks()
    def self.quarks()
        M54::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
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
        M54::put(quark)
        quark
    end

    # --------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        "[quark] #{NereidInterface::toString(quark["nereiduuid"])}"
    end

    # Quarks::getOrSelectQuarkDxThreadOneParentOrNull(quark)
    def self.getOrSelectQuarkDxThreadOneParentOrNull(quark)
        dxthreads = DxThreadQuarkMapping::getDxThreadsForQuark(quark)
        if dxthreads.size == 0 then
            return nil
        end
        if dxthreads.size == 1 then
            return dxthreads[0]
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("DxThread", dxthreads, lambda { |dxthread| DxThreads::toString(dxthread) })
    end

    # --------------------------------------------------

    # Quarks::access(quark)
    def self.access(quark)
        NereidInterface::access(quark["nereiduuid"])
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if M54::getOrNull(quark["uuid"]).nil?
            quark = M54::getOrNull(quark["uuid"]) # could have been transmuted in the previous loop

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow
            puts "ordinal: #{DxThreadQuarkMapping::getQuarkOrdinal(quark)}".yellow

            puts ""

            DxThreadQuarkMapping::getDxThreadsForQuark(quark).each{|dxthread|
                mx.item(
                    "source: #{DxThreads::toString(dxthread)}",
                    lambda { DxThreads::landing(dxthread) }
                )
            }

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quarks::access(quark) }
            )

            mx.item("start".yellow, lambda { 
                dxthread = Quarks::getOrSelectQuarkDxThreadOneParentOrNull(quark)
                DxThreadsUIUtils::runDxThreadQuarkPair(dxthread, quark)
            })

            mx.item("set/update ordinal".yellow, lambda {
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ")
                return if ordinal == ""
                DxThreadQuarkMapping::setQuarkOrdinal(quark, ordinal.to_f)
            })

            mx.item("move to another DxThread".yellow, lambda {
                dxthread = Quarks::getOrSelectQuarkDxThreadOneParentOrNull(quark)
                Patricia::moveTargetToNewDxThread(quark, dxthread)
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
        M54::destroy(quark)
    end

    # Quarks::destroyQuarkAndNereidContent(quark)
    def self.destroyQuarkAndNereidContent(quark)
        status = NereidInterface::destroyElement(quark["nereiduuid"])
        return if !status
        M54::destroy(quark)
    end
end
