# encoding: UTF-8

class Sx01Snapshots

    # ----------------------------------------------------------------------
    # IO

    # Sx01Snapshots::items()
    def self.items()
        Librarian19InMemoryObjectDatabase::getObjectsByMikuType("Sx01")
    end

    # Sx01Snapshots::getOrNull(uuid)
    def self.getOrNull(uuid)
        Librarian19InMemoryObjectDatabase::getObjectByUUIDOrNull(uuid)
    end

    # Sx01Snapshots::destroy(uuid)
    def self.destroy(uuid)
        Librarian19InMemoryObjectDatabase::destroy(uuid)
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
        objects = Librarian19InMemoryObjectDatabase::objects()
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
        Librarian19InMemoryObjectDatabase::commit(item)
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

    # Sx01Snapshots::snapshotIsDeployed()
    def self.snapshotIsDeployed()
        !$Librarian19DeployedSnapshot.nil?
    end

    # ----------------------------------------------------------------------
    # Operations

    # Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant() # boolean indicated if something was printed
    def self.printSnapshotDeploymentStatusIfRelevant()
        snapshot = $Librarian19DeployedSnapshot
        return false if snapshot.nil?
        puts "Deployed Snapshot: #{snapshot["datetime"]} 🕗".green
        true
    end

    # Sx01Snapshots::interactivelySelectAndDeploySnapshot()
    def self.interactivelySelectAndDeploySnapshot()
        snapshot = Sx01Snapshots::interactivelySelectSnapshotOrNull()
        return if snapshot.nil?
        objects = Sx01Snapshots::snapshotToLibrarianObjects(snapshot)
        Librarian19InMemoryObjectDatabase::rebuildInMemoryDatabaseFromObjects(objects)
        $Librarian19DeployedSnapshot = snapshot
    end
end
