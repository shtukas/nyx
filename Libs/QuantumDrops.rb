
class QuantumDrops

    # QuantumDrops::issueNewDrop(uuid, quantumStates)
    def self.issueNewDrop(uuid, quantumStates)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxQuantumDrop",
            "quantumStates" => quantumStates
        }
        # We can file system check the drop here
        filename = "QuantumDrop-#{uuid}"
        filepath = "#{Config::userHomeDirectory()}/Desktop/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        puts "I have put the drop on the Desktop (#{filename})"
        LucilleCore::pressEnterToContinue()
        item
    end

    # QuantumDrops::quantumDropToLastQuantumStateOrNull(drop)
    def self.quantumDropToLastQuantumStateOrNull(drop)
        drop["quantumStates"]
            .sort{|s1, s2| s1["unixtime"] <=> s2["unixtime"] }
            .last
    end

    # QuantumDrops::accessNxQuantumDrop(drop)
    def self.accessNxQuantumDrop(drop)
        lastQuantumState = QuantumDrops::quantumDropToLastQuantumStateOrNull(drop)
        if lastQuantumState then
            rootnhash = lastQuantumState["rootnhash"]
            database  = lastQuantumState["database"]
            Nx113Access::accessAionPoint(rootnhash, database)
        else
            puts "There are no NxQuantumStates in this NxQuantumDrop"
            LucilleCore::pressEnterToContinue()
        end
    end

    # QuantumDrops::editNxQuantumDrop(drop)
    def self.editNxQuantumDrop(drop) # NxQuantumDrop
        lastQuantumState = QuantumDrops::quantumDropToLastQuantumStateOrNull(drop)
        if lastQuantumState then
            packet = Nx113Edit::editAionPointComponents(lastQuantumState["rootnhash"], lastQuantumState["database"])
            quantumState = {
                "uuid"      => SecureRandom.uuid,
                "mikuType"  => "NxQuantumState",
                "unixtime"  => Time.new.to_f,
                "rootnhash" => packet["rootnhash"],
                "database"  => packet["database"]
            }
            FileSystemCheck::fsck_NxQuantumState(quantumState, SecureRandom.hex, true)
            drop["quantumStates"] << quantumState
            FileSystemCheck::fsck_NxQuantumDrop(drop, SecureRandom.hex, true)
            return drop
        else
            nx113 = Nx113Make::interactivelyMakeNx113AionPoint()
            quantumState = {
                "uuid"      => SecureRandom.uuid,
                "mikuType"  => "NxQuantumState",
                "unixtime"  => Time.new.to_f,
                "rootnhash" => nx113["rootnhash"],
                "database"  => nx113["database"]
            }
            FileSystemCheck::fsck_NxQuantumState(quantumState, SecureRandom.hex, true)
            drop["quantumStates"] << quantumState
            FileSystemCheck::fsck_NxQuantumDrop(drop, SecureRandom.hex, true)
            return drop
        end
    end

    # QuantumDrops::quantumDropFilesEnumerator(drop)
    def self.quantumDropFilesEnumerator(drop)
        filename = "QuantumDrop-#{drop["uuid"]}"
        Enumerator.new do |filepaths|
            Find.find(Config::pathToGalaxy()) do |path|
                if File.basename(path) == filename then
                    filepaths << path
                end
            end
        end
    end

    # QuantumDrops::propagateDropAtDropFile(drop, dropfilepath)
    def self.propagateDropAtDropFile(drop, dropfilepath)
        dropOnDisk = JSON.parse(IO.read(dropfilepath))
        return if dropOnDisk["quantumStates"].size == drop["quantumStates"].size
        puts "Going to propagate #{JSON.pretty_generate(drop)} at file: #{dropfilepath}"

        # We now just need to export the QuantumState at at folder
        quantumState = QuantumDrops::quantumDropToLastQuantumStateOrNull(drop)
        puts "quantumState: #{JSON.pretty_generate(quantumState)}"
        return if quantumState.nil?
        rootnhash = quantumState["rootnhash"]
        database  = quantumState["database"]
        exportDirectory = File.dirname(dropfilepath)
        Nx113Access::accessAionPointAtExportDirectory(rootnhash, database, exportDirectory)

        File.open(dropfilepath, "w"){|f| f.puts(JSON.pretty_generate(drop)) }
    end

    # QuantumDrops::propagateQuantumDrop(drop)
    def self.propagateQuantumDrop(drop)
        puts "QuantumDrops::propagateQuantumDrop(#{JSON.pretty_generate(drop)})"
        QuantumDrops::quantumDropFilesEnumerator(drop)
            .each{|filepath|
                QuantumDrops::propagateDropAtDropFile(drop, filepath)
            }
    end

end
