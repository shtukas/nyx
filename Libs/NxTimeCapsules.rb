
class NxTimeCapsules
    # NxTimeCapsules::operate()
    def self.operate()
        N1DataIO::getMikuType("NxTimeCapsule").each{|item|
            if Time.new.to_i > item["unixtime"] then
                BankCore::put(item["account"], item["value"])
                N1DataIO::destroy(item["uuid"])
            end
        }
    end

    # NxTimeCapsules::issueCapsule(unixtime, account, value)
    def self.issueCapsule(unixtime, account, value)
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxTimeCapsule",
            "unixtime" => unixtime,
            "account"  => account,
            "value"    => value
        }
        N1DataIO::commitObject(item)
    end
end