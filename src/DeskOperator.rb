
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForNSDataline(ns1)
    def self.deskFolderpathForNSDataline(ns1)
        "#{Realms::getDeskFolderpath()}/#{ns1["uuid"]}"
    end

    # DeskOperator::deskFolderpathForNSDatalineCreateIfNotExists(ns1, ns0)
    def self.deskFolderpathForNSDatalineCreateIfNotExists(ns1, ns0)
        desk_folderpath_for_ns1 = DeskOperator::deskFolderpathForNSDataline(ns1)
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
            datalineuuid = File.basename(location)
            dataline = NSDataLine::getOrNull(datalineuuid)
            next if dataline.nil?
            puts NSDataLine::toString(dataline)
            datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
            next if datapoint.nil?
            if datapoint["type"] != "aion-point" then # Looks like the point has been transmuted after it was exported as a aion-point
                LucilleCore::removeFileSystemLocation(location)
                next
            end
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            if namedhash == datapoint["namedhash"] then # No change since exported
                LucilleCore::removeFileSystemLocation(location)
                next
            end
            newdatapoint = NSDataPoint::issueAionPoint(namedhash)
            Arrows::issueOrException(dataline, newdatapoint)
            puts "new newdatapoint:"
            puts JSON.pretty_generate(newdatapoint)
            LucilleCore::removeFileSystemLocation(location)
        }
    end
end
