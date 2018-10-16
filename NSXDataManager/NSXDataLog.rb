# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

# ------------------------------------------------------------

DATALOGFOLDERPATH = "/Galaxy/DataBank/Catalyst/Data-Log"

class NSXDataLog

    # NyxDataStorageInterface::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NyxDataStorageInterface::l22ToFolderPath(l22)
    def self.l22ToFolderPath(l22)
        # Example: "20181016-171610-585020"
        folderpath1 = "#{DATALOGFOLDERPATH}/#{l22[0,4]}/#{l22[0,6]}/#{l22[0,8]}"
        if !File.exists?(folderpath1) then
            FileUtils.mkpath folderpath1
        end
        LucilleCore::indexsubfolderpath(folderpath1) # This creates the sub-folder.
    end

    # NyxDataStorageInterface::getNewDataLogItemFilepath()
    def self.getNewDataLogItemFilepath()
        l22 = NyxDataStorageInterface::timeStringL22()
        folderpath = NyxDataStorageInterface::l22ToFolderPath(l22)
        filepath = "#{folderpath}/#{l22}.dataLogItem.txt"
        filepath
    end

    # NyxDataStorageInterface::commitDataLogInstructionToDisk(instruction)
    def self.commitDataLogInstructionToDisk(instruction)
        File.open(NyxDataStorageInterface::getNewDataLogItemFilepath(), "w"){|f| f.write(instruction) }
    end

    # NyxDataStorageInterface::instructionsEnumerator()
    def self.instructionsEnumerator()
        Enumerator.new do |instructions|
            Find.find(DATALOGFOLDERPATH) do |path|
                next if !File.file?(path)
                next if path[-16, 16] != ".dataLogItem.txt"
                instructions << IO.read(path).strip
            end
        end
    end

    # NyxDataStorageInterface::commitObjectToDisk(object)
    def self.commitObjectToDisk(object)
        NyxDataStorageInterface::commitDataLogInstructionToDisk("e1042ee3:#{JSON.generate(object)}")
    end

    # NyxDataStorageInterface::destroyObjectOnDisk(objectuuid)
    def self.destroyObjectOnDisk(objectuuid)
        NyxDataStorageInterface::commitDataLogInstructionToDisk("3c900998:#{objectuuid}")
    end

    # NyxDataStorageInterface::loadDatasetNX2022FromDisk()
    def self.loadDatasetNX2022FromDisk()
        dataset = {}
        NyxDataStorageInterface::instructionsEnumerator()
            .each{|instruction|
                if instruction.start_with?("e1042ee3:") then
                    object = JSON.parse(instruction[9,instruction.size])
                    dataset[object["uuid"]] = object
                end
                if instruction.start_with?("3c900998:") then
                    uuid = instruction[9,instruction.size]
                    dataset.delete(uuid)
                end
            }
        dataset
    end

end


