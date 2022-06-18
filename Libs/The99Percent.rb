# encoding: UTF-8

class The99Percent

    # reference = {
    #     "count"    =>
    #     "datetime" =>
    # }

    # The99Percent::issueNewReference()
    def self.issueNewReference()
        count = The99Percent::getCurrentCount()
        reference = {
            "count"    => count,
            "datetime" => Time.new.to_s
        }
        puts "Issuing a new reference:".green
        puts JSON.pretty_generate(reference).green
        LucilleCore::pressEnterToContinue()
        XCache::set("002c358b-e6ee-41bd-9bee-105396a6349a", JSON.generate(reference))
        reference
    end

    # The99Percent::getReference()
    def self.getReference()
        reference = XCache::getOrNull("002c358b-e6ee-41bd-9bee-105396a6349a")
        if reference then
            JSON.parse(reference)
        else
            The99Percent::issueNewReference()
        end
    end

    # The99Percent::getCurrentCount()
    def self.getCurrentCount()
        TxDateds::items().size + NxShip::items().size + TxTodos::items().size
    end

    # The99Percent::ratio()
    def self.ratio()
        reference = The99Percent::getReference()
        current   = The99Percent::getCurrentCount()
        current.to_f/reference["count"]
    end
end
