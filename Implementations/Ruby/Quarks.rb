
# encoding: UTF-8

class Quarks

    # Quarks::quarks()
    def self.quarks()
        TodoCoreData::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
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
        TodoCoreData::put(quark)
        quark
    end

    # --------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        "[quark] #{NereidInterface::toString(quark["nereiduuid"])}"
    end


    # Quarks::getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
    def self.getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
        quark = quarkOpt ? quarkOpt : Quarks::issueNewQuarkInteractivelyOrNull()
        return nil if quark.nil?
        ordinal = DxThreads::determineQuarkPlacingOrdinal()
        QuarksOrdinals::setQuarkOrdinal(quark, ordinal)
        Patricia::landing(quark)
        quark
    end

    # --------------------------------------------------

    # Quarks::access(quark)
    def self.access(quark)
        NereidInterface::access(quark["nereiduuid"])
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if TodoCoreData::getOrNull(quark["uuid"]).nil?
            quark = TodoCoreData::getOrNull(quark["uuid"]) # could have been transmuted in the previous loop

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow
            puts "ordinal: #{QuarksOrdinals::getQuarkOrdinalOrZero(quark)}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(quark["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "recoveredDailyTimeInHours: #{BankExtended::recoveredDailyTimeInHours(quark["uuid"])}".yellow

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quarks::access(quark) }
            )

            mx.item("set/update ordinal".yellow, lambda {
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ")
                return if ordinal == ""
                QuarksOrdinals::setQuarkOrdinal(quark, ordinal.to_f)
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
        TodoCoreData::destroy(quark)
    end

    # Quarks::destroyQuarkAndNereidContent(quark)
    def self.destroyQuarkAndNereidContent(quark)
        status = NereidInterface::destroyElement(quark["nereiduuid"])
        return if !status
        TodoCoreData::destroy(quark)
    end
end
