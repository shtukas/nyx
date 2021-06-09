# encoding: UTF-8

class Nx50s

    # Nx50s::isFull()
    def self.isFull()
        CoreDataTx::getObjectsBySchema("Nx50").size >= 50
    end

    # Nx50s::importURLAsNewURLNx50(url)
    def self.importURLAsNewURLNx50(url)
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "Nx50"
        quark["unixtime"]    = Time.new.to_f
        quark["description"] = url
        quark["contentType"] = "Url"
        quark["payload"]     = url

        CoreDataTx::commit(quark)
    end

    # Nx50s::importLocationAsNewAionPointNx50(location)
    def self.importLocationAsNewAionPointNx50(location)
        uuid = SecureRandom.uuid

        quark = {}
        quark["uuid"]        = uuid
        quark["schema"]      = "Nx50"
        quark["unixtime"]    = Time.new.to_f
        quark["description"] = File.basename(location) 
        quark["contentType"] = "AionPoint"
        quark["payload"]     = AionCore::commitLocationReturnHash(El1zabeth.new(), location)

        CoreDataTx::commit(quark)
    end

    # Nx50s::maintenance()
    def self.maintenance()
        if CoreDataTx::getObjectsBySchema("Nx50").size <= 20 then
            Quarks::quarks()
                .sample(20)
                .each{|object|
                    object["schema"] = "Nx50"
                    CoreDataTx::commit(object)
                }
        end
    end

    # Nx50s::toNS15(nx50)
    def self.toNS15(nx50)
        uuid = nx50["uuid"]

        announce = "[nx50] #{nx50["description"]}"

        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Quarks::runQuark(nx50) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Quarks::toString(nx50)}' ? ", true) then
                    CoreDataTx::delete(nx50["uuid"])
                end
            },
            "x-source"          => "Nx50s",
            "x-stdRecoveryTime" => BankExtended::stdRecoveredDailyTimeInHours(uuid),
            "x-24Timespan"      => Bank::valueOverTimespan(uuid, 86400)
        }
    end

    # Nx50s::ns15s()
    def self.ns15s()
        # Visible, less than one hour in the past day, highest stdRecoveredDailyTime first

        CoreDataTx::getObjectsBySchema("Nx50")
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .map{|nx50| Nx50s::toNS15(nx50) }
            .select{|nx50| nx50["x-24Timespan" ] < 3600 }
            .sort{|i1, i2| i1["x-stdRecoveryTime"] <=> i2["x-stdRecoveryTime"] }
            .reverse
            .map{|ns15|  
                ns15["announce"] = ns15["announce"].red
                ns15
            }
    end
end