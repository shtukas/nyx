
# encoding: UTF-8

class Quarks

    # Quarks::databaseFilepath()
    def self.databaseFilepath()
        "#{Utils::catalystDataCenterFolderpath()}/Quarks.sqlite3"
    end

    # Quarks::issueQuarkUsingNereiduuid(nereiduuid)
    def self.issueQuarkUsingNereiduuid(nereiduuid)
        uuid = LucilleCore::timeStringL22()
        db = SQLite3::Database.new(Quarks::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "insert into _quarks_ (_uuid_, _nereiduuid_) values (?,?)", [uuid, nereiduuid]
        db.close
        Quarks::getQuarkByUUIDOrNull(uuid)
    end

    # Quarks::getQuarkByUUIDOrNull(uuid)
    def self.getQuarkByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Quarks::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _quarks_ where _uuid_=?" , [uuid]) do |row|
            answer = {
                "uuid"       => row["_uuid_"],
                "nereiduuid" => row["_nereiduuid_"]
            }
        end
        db.close
        answer
    end

    # Quarks::quarks()
    def self.quarks()
        db = SQLite3::Database.new(Quarks::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _quarks_" , []) do |row|
            answer << {
                "uuid"       => row["_uuid_"],
                "nereiduuid" => row["_nereiduuid_"]
            }
        end
        db.close
        answer
    end

    # Quarks::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(Quarks::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _quarks_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # --------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        "[quark] #{AsteroidsInterface::asteroidUUIDToString(quark["nereiduuid"])}"
    end

    # Quarks::issueNewQuarkInteractivelyOrNull()
    def self.issueNewQuarkInteractivelyOrNull()
        asteroid = AsteroidsInterface::interactivelyIssueNewAsteroidOrNull()
        return nil if asteroid.nil?
        Quarks::issueQuarkUsingNereiduuid(asteroid["uuid"])
    end

    # Quarks::issueQuarkUsingNereiduuidAndPlaceAtLowOrdinal(nereiduuid)
    def self.issueQuarkUsingNereiduuidAndPlaceAtLowOrdinal(nereiduuid)
        quark = Quarks::issueQuarkUsingNereiduuid(nereiduuid)
        ordinal = Quarks::computeLowOrdinal()
        QuarksOrdinals::setQuarkOrdinal(quark, ordinal)
    end

    # Quarks::getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
    def self.getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
        quark = quarkOpt ? quarkOpt : Quarks::issueNewQuarkInteractivelyOrNull()
        return nil if quark.nil?
        ordinal = Quarks::determineQuarkPlacingOrdinal()
        QuarksOrdinals::setQuarkOrdinal(quark, ordinal)
        Quarks::landing(quark)
        quark
    end

    # --------------------------------------------------

    # Quarks::access(quark)
    def self.access(quark)
        AsteroidsInterface::access(quark["nereiduuid"])
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if Quarks::getQuarkByUUIDOrNull(quark["uuid"]).nil?
            quark = Quarks::getQuarkByUUIDOrNull(quark["uuid"]) # Could have been transmuted in the previous loop

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
                AsteroidsInterface::edit(quark["nereiduuid"])
            })

            mx.item("transmute".yellow, lambda { 
                AsteroidsInterface::transmuteOrNull(quark["nereiduuid"])
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

    # Quarks::destroyQuarkAndNereidContent(quark)
    def self.destroyQuarkAndNereidContent(quark)
        AsteroidsInterface::destroyAsteroid(quark["nereiduuid"])
        Quarks::destroy(quark["uuid"])
    end

    # Quarks::computeLowOrdinal()
    def self.computeLowOrdinal()
        ordinals = QuarksOrdinals::getOrdinals()
                    .sort
        if ordinals.empty? then
            return 1
        end
        ordinals = ordinals.take(20)
        t0 = DateTime.parse("2021-04-01T00:00:00").to_time.to_i
        shift = (Time.new.to_f - t0).to_f/(86400*365)
        ordinals.last + shift
    end

    # Quarks::determineQuarkPlacingOrdinal()
    def self.determineQuarkPlacingOrdinal()
        puts "Placement ordinal listing"
        command = LucilleCore::askQuestionAnswerAsString("placement ordinal ('low' #default, 'last'): ")
        if command == "low" or command == "" then
            return Quarks::computeLowOrdinal()
        end
        QuarksOrdinals::getNextOrdinal()
    end

    # Quarks::ns16s()
    def self.ns16s()

        toString = lambda {|quark|
            "(ord: #{"%7.3f" % QuarksOrdinals::getQuarkOrdinalOrZero(quark)}, rt: #{"%5.3f" % BankExtended::recoveredDailyTimeInHours(quark["uuid"]).round(3)}) #{Quarks::toString(quark)}"
        }

        streamDepth = 10

        # We fix the uuids that we are going to work with for a duration of two hours

        thisSlotUUIDs = (lambda {
            storageKey = Utils::getNewValueEveryNSeconds("5c47e435-899c-4ab7-96c6-0b941cf2dd8f", 2*3600)
            uuids = KeyValueStore::getOrNull(nil, storageKey)
            if uuids then
                return JSON.parse(uuids)
            end
            uuids = QuarksOrdinals::firstNVisibleQuarksInOrdinalOrder(streamDepth).map{|quark| quark["uuid"]}
            KeyValueStore::set(nil, storageKey, JSON.generate(uuids))
            uuids
        }).call()

        # We intersect the quarks for the database with the uuids of the current slot

        QuarksOrdinals::firstNVisibleQuarksInOrdinalOrder(streamDepth)
            .select{|quark| thisSlotUUIDs.include?(quark["uuid"])}
            .map{|quark|
                {
                    "uuid"     => quark["uuid"],
                    "announce" => "(#{"%5.3f" % BankExtended::recoveredDailyTimeInHours(quark["uuid"])}) #{Quarks::toString(quark)}",
                    "start"    => lambda{ Quarks::runQuark(quark) },
                    "done"     => lambda{
                        if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(quark)}' ? ", true) then
                            Quarks::destroyQuarkAndNereidContent(quark)
                        end
                    },
                    "recoveryTimeInHours" => BankExtended::recoveredDailyTimeInHours(quark["uuid"])
                }
            }
            .select{|quark| DoNotShowUntil::isVisible(quark["uuid"]) }
    end

    # Quarks::runQuark(quark)
    def self.runQuark(quark)

        startUnixtime = Time.new.to_f

        thr = Thread.new {
            sleep 3600
            loop {
                Utils::onScreenNotification("Catalyst", "Quark running for more than an hour")
                sleep 60
            }
        }

        if AsteroidsInterface::getAsteroidOrNull(quark["nereiduuid"]).nil? then
            # The quark is obviously alive but the corresponding nereid item is dead
            puts Quarks::toString(quark).green
            if LucilleCore::askQuestionAnswerAsBoolean("Should I delete this quark ? ") then
                Quarks::destroyQuarkAndNereidContent(quark)
            end
            return
        end

        puts "running: #{Quarks::toString(quark).green}"
        AsteroidsInterface::accessTodoListingEdition(quark["nereiduuid"])

        puts "landing | ++ # Postpone quark by an hour | + <weekday> # Postpone quark | + <float> <datecode unit> # Postpone quark | destroy | ;; # destroy | (empty) # default # exit".yellow

        loop {

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("landing", command) then
                Quarks::landing(quark)
            end

            if Interpreting::match("++", command) then
                DoNotShowUntil::setUnixtime(quark["uuid"], Time.new.to_i+3600)
                break
            end

            if Interpreting::match("+ *", command) then
                _, input = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{input}")
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
                break
            end

            if Interpreting::match("+ * *", command) then
                _, amount, unit = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(quark["uuid"], unixtime)
                break
            end

            if Interpreting::match("destroy", command) then
                AsteroidsInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"]) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
                Quarks::destroyQuarkAndNereidContent(quark)
                break
            end

            if Interpreting::match(";;", command) then
                AsteroidsInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"]) # we need to do it here because after the Neired content destroy, the one at the ottom won't work
                Quarks::destroyQuarkAndNereidContent(quark)
                break
            end

            if Interpreting::match("", command) then
                break
            end
        }

        thr.exit

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{timespan}"

        timespan = [timespan, 3600*2].min
        puts "putting #{timespan} seconds to quark: #{Quarks::toString(quark)}"
        Bank::put(quark["uuid"], timespan)

        AsteroidsInterface::postAccessCleanUpTodoListingEdition(quark["nereiduuid"])
    end
end
