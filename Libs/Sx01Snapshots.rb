# encoding: UTF-8

#$Sx01SnapshotsSuperStructure1 = {
#    "snapshot" => nil,
#    "objects"  => nil # Array[Objects]
#}

$Sx01SnapshotsSuperStructure1 = nil

class Sx01Snapshots

    # ----------------------------------------------------------------------
    # IO

    # Sx01Snapshots::items()
    def self.items()
        Librarian6ObjectsLocal::getObjectsByMikuType("Sx01")
    end

    # Sx01Snapshots::getOrNull(uuid)
    def self.getOrNull(uuid)
        Librarian6ObjectsLocal::getObjectByUUIDOrNull(uuid)
    end

    # Sx01Snapshots::destroy(uuid)
    def self.destroy(uuid)
        Librarian6ObjectsLocal::destroy(uuid)
    end

    # Sx01Snapshots::snapshotToLibrarianObjects(snapshot)
    def self.snapshotToLibrarianObjects(snapshot)
        InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::getBlobOrNull(snapshot["objects"])
            .lines
            .map{|line| JSON.parse(line) }
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # Sx01Snapshots::buildSnapshotTxtFileFromCurrentDatabaseObjects() 
    def self.buildSnapshotTxtFileFromCurrentDatabaseObjects()
        # We take the objects and dump them into a file
        objects = Librarian6ObjectsLocal::objects()
        objects
            .map{|object|
                JSON.generate(object)
            }
            .join("\n")
    end

    # Sx01Snapshots::issueNewSnapshotUsingCurrentDatabaseObjects()
    def self.issueNewSnapshotUsingCurrentDatabaseObjects()
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        blob = Sx01Snapshots::buildSnapshotTxtFileFromCurrentDatabaseObjects()
        item = {
            "uuid"     => uuid,
            "mikuType" => "Sx01",
            "unixtime" => Time.new.to_i,
            "datetime" => Time.new.utc.iso8601,
            "objects"  => InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::putBlob(blob)
        }
        Librarian6ObjectsLocal::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Sx01Snapshots::toString(item)
    def self.toString(item)
        "(snapshot) #{item["datetime"]}"
    end

    # Sx01Snapshots::interactivelySelectSnapshotOrNull()
    def self.interactivelySelectSnapshotOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("snapshot", Sx01Snapshots::items(), lambda{|item| Sx01Snapshots::toString(item) })
    end

    # Sx01Snapshots::getDeployedSnapshotOrNull()
    def self.getDeployedSnapshotOrNull()
        return nil if $Sx01SnapshotsSuperStructure1.nil?
        $Sx01SnapshotsSuperStructure1["snapshot"].clone
    end

    # Sx01Snapshots::snapshotIsDeployed()
    def self.snapshotIsDeployed()
        !$Sx01SnapshotsSuperStructure1.nil?
    end

    # Sx01Snapshots::getDeployedSnapshotLibrarianObjects()
    def self.getDeployedSnapshotLibrarianObjects()
        if $Sx01SnapshotsSuperStructure1.nil? then
            raise "(error: a0283249-be4c-4bdf-ba50-e72836376120)"
        end
        $Sx01SnapshotsSuperStructure1["objects"]
    end

    # ----------------------------------------------------------------------
    # Operations

    # Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant() # boolean indicated if something was printed
    def self.printSnapshotDeploymentStatusIfRelevant()
        snapshot = Sx01Snapshots::getDeployedSnapshotOrNull()
        return false if snapshot.nil?
        puts "Deployed Snapshot: #{snapshot["datetime"]} 🕗".green
        true
    end

    # Sx01Snapshots::interactivelySelectAndDeploySnapshot()
    def self.interactivelySelectAndDeploySnapshot()
        snapshot = Sx01Snapshots::interactivelySelectSnapshotOrNull()
        return if snapshot.nil?
        $Sx01SnapshotsSuperStructure1 = {
            "snapshot" => snapshot,
            "objects"  => Sx01Snapshots::snapshotToLibrarianObjects(snapshot)
        }
    end
end
