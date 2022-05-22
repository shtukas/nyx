# encoding: UTF-8

class Inbox

    # --------------------------------------------------------------------------
    # TxInbox2 Functions

    # Inbox::txInbox2NS16s()
    def self.txInbox2NS16s()
        Librarian20LocalObjectsStore::getObjectsByMikuType("TxInbox2").map{|item|
            uuid = item["uuid"]
            {
                "uuid"     => uuid,
                "mikuType" => "NS16:TxInbox2",
                "unixtime" => item["unixtime"],
                "announce" => "(inbox) #{item["line"]}",
                "item"     => item
            }
        }
    end

    # Inbox::landingInbox2(item)
    def self.landingInbox2(item)
        Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant()
        puts item["line"]
        if item["aionrootnhash"] then
            AionCore::exportHashAtFolder(EnergyGridElizabeth.new(), item["aionrootnhash"], "/Users/pascal/Desktop")
        end
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["exit (default)", "destroy"])
        if action.nil? or action == "exit" then
            return
        end
        if action == "destroy" then
            Librarian20LocalObjectsStore::logicaldelete(item["uuid"])
            return
        end
    end

    # --------------------------------------------------------------------------
    # Common Interface

    # Inbox::ns16s()
    def self.ns16s()
        Inbox::txInbox2NS16s()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end
