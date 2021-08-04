
# encoding: UTF-8

class WorkOrdering

    # WorkOrdering::decideOrdinal(description)
    def self.decideOrdinal(description)
        system("clear")
        # We need to
        # 1. Get all the ns16s valid for the current domain
        # 2. Filter on those which have an ordinal
        # 3. Sort them
        # 4. Present them
        # 5. Extract a new value
        NS16sOperator::getVisibleNS16sForDomain(Domains::workDomain())
            .select{|ns16| !WorkOrdering::getItemOrdinalOrNull(ns16["uuid"]).nil? }
            .sort{|n1, n2| WorkOrdering::getItemOrdinalOrNull(n1["uuid"]) <=> WorkOrdering::getItemOrdinalOrNull(n2["uuid"]) }
            .each{|ns16|
                puts "(#{"%7.3f" % WorkOrdering::getItemOrdinalOrNull(ns16["uuid"])}) #{ns16["announce"]}"
            }
        puts ""
        puts description.green
        puts ""
        LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
    end

    # WorkOrdering::getItemOrdinalOrNull(uuid)
    def self.getItemOrdinalOrNull(uuid)
        ordinal = KeyValueStore::getOrNull(nil, "dd380456-685a-4302-8dd6-7467a17bbc6b:#{uuid}")
        return nil if ordinal.nil?
        ordinal.to_f
    end

    # WorkOrdering::getItemOrdinalPossiblyInteractivelyDecided(uuid, description)
    def self.getItemOrdinalPossiblyInteractivelyDecided(uuid, description)
        ordinal = WorkOrdering::getItemOrdinalOrNull(uuid)
        return ordinal if ordinal
        ordinal = WorkOrdering::decideOrdinal(description)
        KeyValueStore::set(nil, "dd380456-685a-4302-8dd6-7467a17bbc6b:#{uuid}", ordinal)
        ordinal
    end

    # WorkOrdering::resetOrdinal(uuid, description)
    def self.resetOrdinal(uuid, description)
        ordinal = WorkOrdering::decideOrdinal(description)
        KeyValueStore::set(nil, "dd380456-685a-4302-8dd6-7467a17bbc6b:#{uuid}", ordinal)
    end

    # WorkOrdering::ordinalString(uuid)
    def self.ordinalString(uuid)
        ordinal = WorkOrdering::getItemOrdinalOrNull(uuid)
        return "" if ordinal.nil?
        "(#{"%7.3f" % ordinal})"
    end
end

class Work

    # ---------------------------------------------------------------------------

    # Work::shouldBeRunning()
    def self.shouldBeRunning()
        (1..5).include?(Time.new.wday) and Time.new.hour >= 9 and Time.new.hour < 17
    end

    # ---------------------------------------------------------------------------

    # Work::targetRT()
    def self.targetRT()
        6
    end

    # ---------------------------------------------------------------------------

    # Work::itemAccess(location)
    def self.itemAccess(location)

        uuid = Digest::SHA1.hexdigest("7f62221b-6b85-47ef-bd5d-72bd17e21fc4:#{location}")

        nxball = NxBalls::makeNxBall([uuid, "WORK-E4A9-4BCD-9824-1EEC4D648408", Domains::workDomain()["uuid"]])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Work item running for more than an hour")
                end
            }
        }

        loop {
            system("clear")
            puts "[work item] #{location}".green

            puts "access | <datecode> | detach running | exit".yellow
            puts UIServices::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == "exit"

            if command == "access" then
                system("open '#{location}'")
                next
            end

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2("[work item] #{location}", Time.new.to_i, [uuid, "WORK-E4A9-4BCD-9824-1EEC4D648408", Domains::workDomain()["uuid"]])
                break
            end

            UIServices::mainMenuInterpreter(command)
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Work::ns16s(domain)
    def self.ns16s(domain)
        return [] if (domain["uuid"] != Domains::workDomain()["uuid"])

        folderpath = Utils::locationByUniqueStringOrNull("8ead151f04")
        LucilleCore::locationsAtFolder(folderpath).map{|location|
            {
                "uuid"      => Digest::SHA1.hexdigest("7f62221b-6b85-47ef-bd5d-72bd17e21fc4:#{location}"),
                "announce"  => "[#{"work".yellow}] [fold] #{File.basename(location)}",
                "access"    => lambda { Work::itemAccess(location) },
                "done"      => nil,
                "domain"    => Domains::workDomain()
            }
        }
    end

    # Work::nx19s()
    def self.nx19s()
        [
            {
                "announce" => "work",
                "lambda"   => lambda { Work::access() }
            }
        ]
    end
end
