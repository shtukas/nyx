
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForNSDataType1(ns1)
    def self.deskFolderpathForNSDataType1(ns1)
        "#{Realms::getDeskFolderpath()}/#{ns1["uuid"]}"
    end

    # DeskOperator::deskFolderpathForNSDataType0CreateIfNotExists(ns1, ns0)
    def self.deskFolderpathForNSDataType0CreateIfNotExists(ns1, ns0)
        desk_folderpath_for_ns1 = DeskOperator::deskFolderpathForNSDataType1(ns1)
        if !File.exists?(desk_folderpath_for_ns1) then
            FileUtils.mkpath(desk_folderpath_for_ns1)
            namedhash = ns0["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_ns1)
            # If the desk_folderpath_for_ns1 folder contains just one folder named after the ns1 itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_ns1.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_ns1}/#{ns1["uuid"]}") then
                FileUtils.mv("#{desk_folderpath_for_ns1}/#{ns1["uuid"]}", "#{desk_folderpath_for_ns1}/#{ns1["uuid"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_ns1}/#{ns1["uuid"]}-lifting", Realms::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns1)
                FileUtils.mv("#{desk_folderpath_for_ns1}-lifting", desk_folderpath_for_ns1)
            end
        end
        desk_folderpath_for_ns1
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        LucilleCore::locationsAtFolder(Realms::getDeskFolderpath()).each{|location|
            cubeuuid = File.basename(location)
            cube = NSDataType1::getCubeOrNull(cubeuuid)
            next if cube.nil?
            puts NSDataType1::cubeToString(cube)
            ns0 = NSDataType1::cubeToLastFrameOrNull(cube)
            next if ns0.nil?
            if ns0["type"] != "aion-point" then # Looks like the cube has been transmuted after it was exported as a aion-point
                LucilleCore::removeFileSystemLocation(location)
                next
            end
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            if namedhash == ns0["namedhash"] then # No change since exported
                LucilleCore::removeFileSystemLocation(location)
                next
            end
            newns0 = NSDataType0s::issueAionPoint(namedhash)
            Arrows::issueOrException(cube, newns0)
            puts "new ns0:"
            puts JSON.pretty_generate(newns0)
            LucilleCore::removeFileSystemLocation(location)
        }
    end
end
