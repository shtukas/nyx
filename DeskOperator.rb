
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForSpin(spin)
    def self.deskFolderpathForSpin(spin)
        "#{EstateServices::getDeskFolderpath()}/#{spin["targetuuid"]}"
    end

    # DeskOperator::deskFolderpathForSpinCreateIfNotExists(spin)
    def self.deskFolderpathForSpinCreateIfNotExists(spin)
        desk_folderpath_for_spin = DeskOperator::deskFolderpathForSpin(spin)
        if !File.exists?(desk_folderpath_for_spin) then
            FileUtils.mkpath(desk_folderpath_for_spin)
            namedhash = spin["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_spin)
            # If the desk_folderpath_for_spin folder contains just one folder named after the spin itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_spin.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_spin}/#{spin["targetuuid"]}") then
                FileUtils.mv("#{desk_folderpath_for_spin}/#{spin["targetuuid"]}", "#{desk_folderpath_for_spin}/#{spin["targetuuid"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_spin}/#{spin["targetuuid"]}-lifting", EstateServices::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_spin)
                FileUtils.mv("#{desk_folderpath_for_spin}-lifting", desk_folderpath_for_spin)
            end
        end
        desk_folderpath_for_spin
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        Spins::spins()
            .each{|spin|
                next if spin["type"] != "aion-point"
                desk_folderpath_for_spin = DeskOperator::deskFolderpathForSpin(spin)
                next if !File.exists?(desk_folderpath_for_spin)
                namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_spin)
                if namedhash == spin["namedhash"] then
                    LucilleCore::removeFileSystemLocation(desk_folderpath_for_spin)
                    next
                end
                # We issue a new spin for the same target
                spin = Spins::issueAionPoint(spin["targetuuid"], namedhash)
                puts JSON.pretty_generate(spin)
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_spin)
            }
    end
end
