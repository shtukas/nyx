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
                    CoreDataTx::commit(quark)
                }
        end
    end

    # Nx50s::ns16s()
    def self.ns16s()
        return [] if (BankExtended::stdRecoveredDailyTimeInHours("QUARKS-404E-A1D2-0777E64077BA") > 2)
        CoreDataTx::getObjectsBySchema("Nx50")
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .first(3)
            .map{|nx50| Quarks::quarkToNS16(nx50) }
    end

end

Thread.new {
    sleep 60
    loop {
        Nx50s::maintenance()
        sleep 3600
    }
}