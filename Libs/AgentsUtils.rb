
class AgentsUtils

    # AgentsUtils::atomLandingPresentation(atomuuid)
    def self.atomLandingPresentation(atomuuid)
        atom = LibrarianObjects::getObjectByUUIDOrNull(atomuuid)
        if atom.nil? then
            puts "warning: I could not find the atom for this item (atomuuid: #{atomuuid})"
            LucilleCore::pressEnterToContinue()
        else
            if text = CoreData5::atomPayloadToTextOrNull(atom) then
                puts "text:\n#{text}"
            end
        end
    end

    # AgentsUtils::accessAtom(atomuuid)
    def self.accessAtom(atomuuid)
        atom = LibrarianObjects::getObjectByUUIDOrNull(atomuuid)
        return if atom.nil?
        return if atom["type"] == "description-only"
        atom = CoreData5::accessWithOptionToEditOptionalUpdate(atom)
        return if atom.nil?
        LibrarianObjects::commit(atom)
    end

    # AgentsUtils::atomTypeForToStrings(prefix, atomuuid)
    def self.atomTypeForToStrings(prefix, atomuuid)
        atom = LibrarianObjects::getObjectByUUIDOrNull(atomuuid)
        return "" if atom.nil?
        "#{prefix}(#{atom["type"]})"
    end
end