# encoding: UTF-8

class Lx01s

    # Lx01s::make(uuid, announce, l)
    def self.make(uuid, announce, l)
        {
            "uuid"     => uuid,
            "mikuType" => "Lx01",
            "announce" => announce,
            "lambda"   => l
        }
    end

    # Lx01s::listingItems()
    def self.listingItems()
        items = []

        unixtime = XCache::getOrDefaultValue("541c04ca-f456-435d-b33b-6ea6f3059f6e", "0").to_f
        if (Time.new.to_i - unixtime) > 3600*8 then
            items << Lx01s::make("ED7B8BE3-755B-40F9-AEEE-02790FD7C952", "AutomaticNx7NetworkMainteance::run()", lambda{
                AutomaticNx7NetworkMainteance::run()
                XCache::set("541c04ca-f456-435d-b33b-6ea6f3059f6e", Time.new.to_i)
            })
        end

        items
    end

end
