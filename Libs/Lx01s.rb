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
        if Config::thisInstanceId() == "Lucille18-pascal" then
            unixtime = XCache::getOrDefaultValue("network-maintenance-time-aa34c002-96b1-43b4-a7fd-275af066150f", "0").to_f
            if (Time.new.to_i - unixtime) > 3600*8 then
                items << Lx01s::make("ED7B8BE3-755B-40F9-AEEE-02790FD7C952", "AutomaticNx7NetworkMainteance::run()", lambda{
                    AutomaticNx7NetworkMainteance::run()
                    XCache::set("network-maintenance-time-aa34c002-96b1-43b4-a7fd-275af066150f", Time.new.to_i)
                })
            end
        end
        items
    end

end
