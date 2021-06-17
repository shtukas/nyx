# encoding: UTF-8

=begin

Nx50s doesn't use NS16s, and use NS15s instead

NS15 {
    "uuid"     : String # used by DoNotShowUntil
    "announce" : String
    "access"   : Lambda or nil # optional
    "done"     : Lambda or nil # optional
    "[]"       : Lambda or nil # optional
}

=end

class Nx50s

    # Nx50s::importURLAsNewURLNx50(url)
    def self.importURLAsNewURLNx50(url)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = url
        nx50["contentType"] = "Url"
        nx50["payload"]     = url

        CoreDataTx::commit(nx50)
    end

    # Nx50s::importLocationAsNewAionPointNx50(location)
    def self.importLocationAsNewAionPointNx50(location)
        uuid = SecureRandom.uuid

        nx50 = {}
        nx50["uuid"]        = uuid
        nx50["schema"]      = "Nx50"
        nx50["unixtime"]    = Time.new.to_f
        nx50["description"] = File.basename(location) 
        nx50["contentType"] = "AionPoint"
        nx50["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        CoreDataTx::commit(nx50)
    end

    # --------------------------------------------------

    # Nx50s::maintenance()
    def self.maintenance()
        if CoreDataTx::getObjectsBySchema("Nx50").size <= 30 then
            CoreDataTx::getObjectsBySchema("quark")
                .sample(20)
                .each{|object|
                    object["schema"] = "Nx50"
                    CoreDataTx::commit(object)
                }
        end
    end

    # Nx50s::landing(quark)
    def self.landing(quark)
        loop {

            system("clear")

            puts Nx50s::toString(quark)

            puts "uuid: #{quark["uuid"]}"
            puts "coordinates: #{quark["contentType"]}, #{quark["payload"]}"

            unixtime = DoNotShowUntil::getUnixtimeOrNull(quark["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}"
            end
            puts "stdRecoveredDailyTimeInHours: #{BankExtended::stdRecoveredDailyTimeInHours(quark["uuid"])}"

            puts "access (partial edit) | edit | transmute | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(quark["contentType"], quark["payload"])
                if coordinates then
                    quark["contentType"] = coordinates[0]
                    quark["payload"]     = coordinates[1]
                    CoreDataTx::commit(quark)
                end
            end

            if Interpreting::match("edit", command) then
                coordinates = Nx102::edit(quark["description"], quark["contentType"], quark["payload"])
                if coordinates then
                    quark["description"] = coordinates[0]
                    quark["contentType"] = coordinates[1]
                    quark["payload"]     = coordinates[2]
                    CoreDataTx::commit(quark)
                end
            end

            if Interpreting::match("transmute", command) then
                Nx102::transmute(quark["description"], quark["contentType"], quark["payload"])
            end

            if Interpreting::match("destroy", command) then
                CoreDataTx::delete(quark["uuid"])
                break
            end
        }
    end

    # --------------------------------------------------

    # Nx50s::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{nx50["description"]}"
    end

    # Nx50s::access(nx50)
    def self.access(nx50)

        uuid = nx50["uuid"]

        nxball = BankExtended::makeNxBall([uuid, "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 item running for more than an hour")
                end
            }
        }

        system("clear")
        
        puts "running: #{Nx50s::toString(nx50)}".green

        coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
        if coordinates then
            nx50["contentType"] = coordinates[0]
            nx50["payload"]     = coordinates[1]
            CoreDataTx::commit(nx50)
        end

        loop {

            return if CoreDataTx::getObjectByIdOrNull(nx50["uuid"]).nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{Nx50s::toString(nx50)}".green

            puts "access | landing | <datecode> | detach running | completed | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(nx50["uuid"], unixtime)
                break
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(nx50["contentType"], nx50["payload"])
                if coordinates then
                    nx50["contentType"] = coordinates[0]
                    nx50["payload"]     = coordinates[1]
                    ProjectItems::commit(nx50)
                end
                next
            end

            if Interpreting::match("landing", command) then
                Nx50s::landing(nx50)
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("completed", command) then
                Nx102::postAccessCleanUp(nx50["contentType"], nx50["payload"])
                CoreDataTx::delete(nx50["uuid"])
                break
            end
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)

        Nx102::postAccessCleanUp(nx50["contentType"], nx50["payload"])
    end

    # Nx50s::toNS16(nx50)
    def self.toNS16(nx50)
        uuid = nx50["uuid"]

        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

        announce = "[nx50] (#{"%4.2f" % rt}) #{nx50["description"]}"

        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Nx50s::access(nx50) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx50s::toString(nx50)}' ? ", true) then
                    CoreDataTx::delete(nx50["uuid"])
                end
            },
            "rt"       => rt
        }
    end

    # Nx50s::ns16sOrdered()
    def self.ns16sOrdered()
        # Visible, less than one hour in the past day, highest stdRecoveredDailyTime first

        items0 = CoreDataTx::getObjectsBySchema("Nx50")
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .map{|nx50| Nx50s::toNS16(nx50) }

        items1 = items0
                    .select{|ns16| ns16["rt"] < 1 }
                    .sort{|i1, i2| i1["rt"] <=> i2["rt"] }
                    .reverse

        items2 = items0
                    .select{|ns16| ns16["rt"] >= 1 }
                    .map{|ns15|
                        ns15["announce"] = ns15["announce"].red
                        ns15
                    }
                    .sort{|i1, i2| i1["rt"] <=> i2["rt"] }

        items1.take(3) + items2 + items1.drop(3)
    end

    # Nx50s::targetForNS17()
    def self.targetForNS17()
        2
    end

    # Nx50s::ns17s()
    def self.ns17s()
        rt = BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7")
        ratio = rt.to_f/Nx50s::targetForNS17()
        [
            {
                "ratio" => ratio,
                "ns16s" => Nx50s::ns16sOrdered().first(6)
            }
        ]
    end

    # Nx50s::ns17text()
    def self.ns17text()
        rt = BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7")
        ratio = rt.to_f/Nx50s::targetForNS17()
        "(ratio: #{"%4.2f" % rt} of #{"%3.1f" % Work::targetRT()}) Nx50s"
    end
end
