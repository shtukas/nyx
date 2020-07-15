
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForFragment(fragment)
    def self.deskFolderpathForFragment(fragment)
        "#{EstateServices::getDeskFolderpath()}/#{fragment["familyname"]}"
    end

    # DeskOperator::deskFolderpathForFragmentCreateIfNotExists(fragment)
    def self.deskFolderpathForFragmentCreateIfNotExists(fragment)
        desk_folderpath_for_fragment = DeskOperator::deskFolderpathForFragment(fragment)
        if !File.exists?(desk_folderpath_for_fragment) then
            FileUtils.mkpath(desk_folderpath_for_fragment)
            namedhash = fragment["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_fragment)
            # If the desk_folderpath_for_fragment folder contains just one folder named after the fragment itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_fragment.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_fragment}/#{fragment["familyname"]}") then
                FileUtils.mv("#{desk_folderpath_for_fragment}/#{fragment["familyname"]}", "#{desk_folderpath_for_fragment}/#{fragment["familyname"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_fragment}/#{fragment["familyname"]}-lifting", EstateServices::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_fragment)
                FileUtils.mv("#{desk_folderpath_for_fragment}-lifting", desk_folderpath_for_fragment)
            end
        end
        desk_folderpath_for_fragment
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        Fragments::fragments()
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }  # We want the last of a family to come first (part 1)
            .reverse                                            # We want the last of a family to come first (part 2)
            .each{|fragment|
                next if fragment["type"] != "aion-point"
                desk_folderpath_for_fragment = DeskOperator::deskFolderpathForFragment(fragment)
                next if !File.exists?(desk_folderpath_for_fragment)
                puts "fragment:"
                puts JSON.pretty_generate(fragment)
                namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_fragment)
                puts "namedhash from folder: #{namedhash}"
                if namedhash == fragment["namedhash"] then
                    LucilleCore::removeFileSystemLocation(desk_folderpath_for_fragment)
                    next
                end
                # We generate new fragment with the same target and the same familyname
                newfragment = Fragments::issueAionPoint(fragment["familyname"], namedhash)
                puts "new fragment:"
                puts JSON.pretty_generate(newfragment)
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_fragment)
            }
    end
end
