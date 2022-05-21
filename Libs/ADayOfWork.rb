# encoding: UTF-8

class ADayOfWork

    # ADayOfWork::universes()
    def self.universes()
        return ["backlog"] if [0, 6].include?(Time.new.wday)
        if Time.new.hour >= 8 and Time.new.hour <= 16 then
            ["work", "backlog"]
        else
            ["backlog"]
        end
    end

    # ADayOfWork::workExpectationInHours()
    def self.workExpectationInHours()
        5
    end

    # ADayOfWork::getTodayWorkGlobalCommitmentOrNull()
    def self.getTodayWorkGlobalCommitmentOrNull()
        return nil if !ADayOfWork::universes().include?("work")
        date = Utils::today()
        object = XCache::getOrNull("0b75dc91-a4ef-4f88-8a35-9fd033aaf1a9:#{date}")
        if object then
            object = JSON.parse(object)
            done_ = Bank::valueAtDate(object["uuid"], date)
            return nil if done_ >= 3600*ADayOfWork::workExpectationInHours()
            left_ = 3600*ADayOfWork::workExpectationInHours() - done_
            object["announce"] = "Work global commitment, done: #{(done_.to_f/3600).round(2)} hours, left: #{(left_.to_f/3600).round(2)} hours"
            return object
        end
        object = {
            "uuid"        => SecureRandom.hex,
            "mikuType"    => "Tx0930",
            "announce"    => "Work global commitment (awaiting first start)",
            "nonListingDefaultable" => true
        }
        XCache::set("0b75dc91-a4ef-4f88-8a35-9fd033aaf1a9:#{date}", JSON.generate(object))
        object
    end

    # ADayOfWork::updateWorkGlobalCommitmentWithDoneSeconds(timeInSeconds)
    def self.updateWorkGlobalCommitmentWithDoneSeconds(timeInSeconds)
        object = ADayOfWork::getTodayWorkGlobalCommitmentOrNull()
        return if object.nil?
        object["secondsleft"] = object["secondsleft"] - timeInSeconds
        XCache::set("0b75dc91-a4ef-4f88-8a35-9fd033aaf1a9:#{date}", JSON.generate(object))
    end

    # ---------------------------------------------------------------------------------------------

    # ADayOfWork::getNS16sForUniverse(universe)
    def self.getNS16sForUniverse(universe)
        [
            Anniversaries::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Waves::ns16sHighPriority(universe),
            TxDateds::ns16s(),
            Inbox::ns16s(),
            Waves::ns16sLowerPriority(universe),
            TxFyres::ns16s(universe),
            TxTodos::ns16s(universe).first(5)
        ].flatten
    end

    # ADayOfWork::getHighPriorityNS16sForUniverse(universe)
    def self.getHighPriorityNS16sForUniverse(universe)
        [
            Anniversaries::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Waves::ns16sHighPriority(universe),
            TxDateds::ns16s(),
            Inbox::ns16s(),
            TxFyres::ns16s(universe)
        ].flatten
    end

    # ADayOfWork::removeRedundancy(items)
    def self.removeRedundancy(items)
        items
            .reduce([]){|selected, item|
                if selected.none?{|x| x["uuid"] == item["uuid"] } then
                    selected + [ item ]
                else
                    selected
                end
            }
    end

    # ADayOfWork::getCoreUUIDs(date)
    def self.getCoreUUIDs(date)
        uuids = XCache::getOrNull("276dc0b9-222c-4dd7-ba8f-88561678ab4a:#{date}")
        return JSON.parse(uuids) if uuids
        ns16s = ADayOfWork::universes().map{|universe| ADayOfWork::getNS16sForUniverse(universe) }.flatten
        ns16s = ADayOfWork::removeRedundancy(ns16s)
        uuids = ns16s.map{|ns16| ns16["uuid"] }
        XCache::set("276dc0b9-222c-4dd7-ba8f-88561678ab4a:#{date}", JSON.generate(uuids))
        uuids
    end

    # ADayOfWork::getNS16s()
    def self.getNS16s()
        date = Utils::today()
        coreuuids = ADayOfWork::getCoreUUIDs(date)
        ns16s0 = [ADayOfWork::getTodayWorkGlobalCommitmentOrNull()].compact
        ns16s1 = ADayOfWork::universes().map{|universe| ADayOfWork::getHighPriorityNS16sForUniverse(universe) }.flatten
        ns16s2 = ADayOfWork::universes().map{|universe| ADayOfWork::getNS16sForUniverse(universe) }.flatten
                    .select{|ns16| coreuuids.include?(ns16["uuid"]) }
        ADayOfWork::removeRedundancy(ns16s0+ns16s1+ns16s2)
            .select{|ns16| DoNotShowUntil::isVisible(ns16["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

end


