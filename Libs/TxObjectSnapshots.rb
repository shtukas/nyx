
# encoding: UTF-8

class TxObjectSnapshots

    # TxObjectSnapshots::items()
    def self.items()
        Librarian6ObjectsLocal::getObjectsByMikuType("TxOS01")
    end

    # TxObjectSnapshots::getObjectSnapshots(objectuuid)
    def self.getObjectSnapshots(objectuuid)
        TxObjectSnapshots::items()
            .select{|item| item["payload"]["uuid"] == objectuuid }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # TxObjectSnapshots::recordVariant(object)
    def self.recordVariant(object)
        object = object.clone
        item = {
            "uuid"       => SecureRandom.uuid,
            "mikuType"   => "TxOS01",
            "unixtime"   => Time.new.to_f,
            "payload"    => object
        }
        Librarian6ObjectsLocal::commit(item)
    end

    # TxObjectSnapshots::toString(item)
    def self.toString(item)
        "(object snapshot) #{Time.at(item["unixtime"]).utc.iso8601}"
    end
end
