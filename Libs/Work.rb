
# encoding: UTF-8

# -----------------------------------------------------------------------

class Work

    # ---------------------------------------------------------------------------

    # Work::shouldBeRunning()
    def self.shouldBeRunning()
        return false if !DoNotShowUntil::isVisible("WORK-E4A9-4BCD-9824-1EEC4D648408")
        return false if (BankExtended::stdRecoveredDailyTimeInHours(Domains::workDomain()["uuid"]) > Work::targetRT())
        return false if [0, 6].include?(Time.new.wday)
        return false if Time.new.hour < 9
        return false if Time.new.hour >= 21
        true
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
                "announce"  => "[#{"work".yellow}] #{File.basename(location)}",
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
