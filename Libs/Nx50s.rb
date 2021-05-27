# encoding: UTF-8

class Nx50s

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

    # Nx50s::nx50sForAgent(agent)
    def self.nx50sForAgent(agent)
        if agent["uuid"] == "3AD70E36-826B-4958-95BF-02E12209C375" then
            CoreDataTx::getObjectsBySchema("Nx50").select{|nx50| nx50["air-traffic-control-agent"].nil? }
        else
            CoreDataTx::getObjectsBySchema("Nx50").select{|nx50| nx50["air-traffic-control-agent"] == agent["uuid"]}
        end
    end

    # Nx50s::quarksForAgent(agent)
    def self.quarksForAgent(agent)
        if agent["uuid"] == "3AD70E36-826B-4958-95BF-02E12209C375" then
            CoreDataTx::getObjectsBySchema("quark").select{|nx50| nx50["air-traffic-control-agent"].nil? }
        else
            CoreDataTx::getObjectsBySchema("quark").select{|nx50| nx50["air-traffic-control-agent"] == agent["uuid"]}
        end
    end

    # Nx50s::maintenance()
    def self.maintenance()
        AirTrafficControl::agents().each{|agent|
            if Nx50s::nx50sForAgent(agent).size < 3 then
                Nx50s::quarksForAgent(agent)
                    .first(3-Nx50s::nx50sForAgent(agent).size)
                    .each{|quark|
                        nx50 = quark.clone
                        nx50["schema"] = "Nx50"
                        CoreDataTx::commit(nx50)
                    }
            end
        }
    end

    # Nx50s::ns16s()
    def self.ns16s()
        CoreDataTx::getObjectsBySchema("Nx50")
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