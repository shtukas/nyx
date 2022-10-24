
class NxGridFiber

    # NxGridFiber::issueNewNxGridFiber(uuid, states)
    def self.issueNewNxGridFiber(uuid, states)
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxGridFiber",
            "unixtime" => Time.new.to_f,
            "datetime" => Time.new.utc.iso8601,
            "states"   => states
        }
        # We can file system check the fiber here
        filename = "REPLACE-THIS-NAME-#{uuid}.NxGridFiber"
        filepath = "#{Config::userHomeDirectory()}/Desktop/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        puts "I have put the NxGridFiber on the Desktop (#{filename})"
        LucilleCore::pressEnterToContinue()
        item
    end

    # NxGridFiber::fiberToLastStateOrNull(fiber)
    def self.fiberToLastStateOrNull(fiber)
        fiber["states"]
            .sort{|s1, s2| s1["unixtime"] <=> s2["unixtime"] }
            .last
    end

    # NxGridFiber::exportStateAtFolder(state, stateExportFolder)
    def self.exportStateAtFolder(state, stateExportFolder)
        if !File.exists?(stateExportFolder) then
            raise "(error: d5574c5e-3ab0-458c-98e2-331278e4fb32) cannot see stateExportFolder: #{stateExportFolder}"
        end
        state["content"].each{|thing|
            rootnhash = thing["rootnhash"]
            database  = thing["database"]
            Nx113Access::accessAionPointAtExportDirectory(rootnhash, database, stateExportFolder)
        }
    end

    # NxGridFiber::accessFiber(fiber)
    def self.accessFiber(fiber)
        state = NxGridFiber::fiberToLastStateOrNull(fiber) # "NxFiberState"
        if state then
            stateExportFolder = "#{ENV['HOME']}/Desktop/grid-state-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(stateExportFolder)
            NxGridFiber::exportStateAtFolder(state, stateExportFolder)
            puts "GridFiber exported at #{stateExportFolder}"
            LucilleCore::pressEnterToContinue()
        else
            puts "There are no NxFiberStates in this NxGridFiber"
            LucilleCore::pressEnterToContinue()
        end
    end

    # NxGridFiber::locationToStateContent(location)
    def self.locationToStateContent(location)
        if !File.exists?(location) then
            raise "(error: b10498fc-8b94-418b-a00d-a8ea7d922e17) #{location}"
        end
        if !File.directory?(location) then
            raise "(error: 1765ea10-524b-45af-a1a9-6ab6b5c664cf) #{location}"
        end
        LucilleCore::locationsAtFolder(location)
            .map{|location|
                nx113 = Nx113Make::aionpoint(location)
                {
                    "mikuType"  => "NxFiberStateItem",
                    "rootnhash" => nx113["rootnhash"],
                    "database"  => nx113["database"]
                }
            }
    end

    # NxGridFiber::locationToNxFiberState(location)
    def self.locationToNxFiberState(location)
        if !File.exists?(location) then
            raise "(error: 8ed386c4-27c0-4a99-8bce-ed7f8c804b8a) #{location}"
        end
        if !File.directory?(location) then
            raise "(error: 5a3cc356-4b8d-4751-99e4-e7cf6b03e961) #{location}"
        end
        content = NxGridFiber::locationToStateContent(location)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxFiberState",
            "unixtime" => Time.new.to_f,
            "content"  => content
        }
    end

    # NxGridFiber::editFiber(fiber)
    def self.editFiber(fiber) # NxGridFiber

        stateExportFolder = "#{ENV['HOME']}/Desktop/grid-state-#{SecureRandom.hex(4)}"
        FileUtils.mkdir(stateExportFolder)

        state = NxGridFiber::fiberToLastStateOrNull(fiber)
        if state then
            NxGridFiber::exportStateAtFolder(state, stateExportFolder)
            puts "GridFiber exported at #{stateExportFolder} (next step: lift)"
            LucilleCore::pressEnterToContinue()
        else
            puts "GridFiber's empty state exported at #{stateExportFolder} (next step: lift)"
            LucilleCore::pressEnterToContinue()
        end
        state = NxGridFiber::locationToNxFiberState(stateExportFolder)
        FileSystemCheck::fsck_NxFiberState(state, SecureRandom.hex, true)
        states = fiber["states"] + [state]
        fiber["states"] = states
        fiber
    end
end

class NxGridFiberFileSystemIntegration

    # NxGridFiberFileSystemIntegration::nxGridFiberFsFilesEnumeratorForFiber(fiberuuid)
    def self.nxGridFiberFsFilesEnumeratorForFiber(fiberuuid)
        Enumerator.new do |filepaths|
            Find.find(Config::pathToGalaxy()) do |path|
                if File.basename(path)[-12, 12] == ".NxGridFiber" then
                    diskFiber = JSON.parse(IO.read(path))
                    if diskFiber["uuid"] == fiberuuid then
                        filepaths << path
                    end
                end
            end
        end
    end

    # NxGridFiberFileSystemIntegration::getNyxNodeByFiberUUIDOrNull(fiberuuid)
    def self.getNyxNodeByFiberUUIDOrNull(fiberuuid)
        NyxNodes::items()
            .select{|item| item["payload_1"]["type"] == "NxGridFiber" }
            .select{|item| item["payload_1"]["fiber"]["uuid"] == fiberuuid }
            .first
    end

    # NxGridFiberFileSystemIntegration::propagateFiberAtDropFile(fiber, fiberFilepath)
    def self.propagateFiberAtDropFile(fiber, fiberFilepath)

        puts "Fiber propagation @ #{fiberFilepath}"
        puts "fiber: #{JSON.pretty_generate(fiber)}"
        puts "fiberFilepath: #{fiberFilepath}"

        if fiber["states"].empty? then
            puts "No state found"
            return
        end

        fiberOnDisk = JSON.parse(IO.read(fiberFilepath))
        
        if (fiber.to_s == fiberOnDisk.to_s) then
            puts "Identical fibers"
            return
        end

        targetfolder = fiberFilepath.gsub(".NxGridFiber", "")
        if !File.exists?(targetfolder) then
            raise "I cannot see expected folder: #{targetfolder}"
        end

        puts "Cleaning before export"
        LucilleCore::locationsAtFolder(targetfolder).each{|location|
            LucilleCore::removeFileSystemLocation(location)
        }

        NxGridFiber::exportStateAtFolder(fiber["states"].last, targetfolder)

        File.open(fiberFilepath, "w"){|f| f.puts(JSON.pretty_generate(fiber)) }
    end

    # NxGridFiberFileSystemIntegration::propagateFiber(fiber)
    def self.propagateFiber(fiber)
        puts "NxGridFiberFileSystemIntegration::propagateFiber(#{JSON.pretty_generate(fiber)})"
        NxGridFiberFileSystemIntegration::nxGridFiberFsFilesEnumeratorForFiber(fiber["uuid"])
            .each{|filepath|
                NxGridFiberFileSystemIntegration::propagateFiberAtDropFile(fiber, filepath)
            }
    end
end
