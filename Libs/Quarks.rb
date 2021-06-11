
# encoding: UTF-8

class Quarks

    # Quarks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "quark"
        quark["unixtime"]    = Time.new.to_f

        coordinates = Nx102::interactivelyIssueNewCoordinates3OrNull()
        return nil if coordinates.nil?

        quark["description"] = coordinates[0]
        quark["contentType"] = coordinates[1]
        quark["payload"]     = coordinates[2]

        CoreDataTx::commit(quark)
    end

    # --------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        "[quark] #{quark["description"]}"
    end

    # Quarks::quarks()
    def self.quarks()
        CoreDataTx::getObjectsBySchema("quark")
    end

    # --------------------------------------------------

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow
            unixtime = DoNotShowUntil::getUnixtimeOrNull(quark["uuid"])
            if unixtime then
                puts "DoNotDisplayUntil: #{Time.at(unixtime).to_s}".yellow
            end
            puts "stdRecoveredDailyTimeInHours: #{BankExtended::stdRecoveredDailyTimeInHours(quark["uuid"])}".yellow

            puts "access (partial edit) | edit | transmute | destroy".yellow

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
end