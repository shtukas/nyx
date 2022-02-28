
class AgentsUtils

    # AgentsUtils::atomLandingPresentation(atomuuid)
    def self.atomLandingPresentation(atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        if atom.nil? then
            puts "warning: I could not find the atom for this item (atomuuid: #{atomuuid})"
            LucilleCore::pressEnterToContinue()
        else
            if text = Librarian5Atoms::atomPayloadToTextOrNull(atom) then
                puts "text:\n#{text}"
            end
        end
    end

    # AgentsUtils::accessAtom(atomuuid)
    def self.accessAtom(atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        return if atom.nil?
        return if atom["type"] == "description-only"
        atom = Librarian5Atoms::accessWithOptionToEditOptionalUpdate(atom)
        return if atom.nil?
        Librarian6Objects::commit(atom)
    end

    # AgentsUtils::atomTypeForToStrings(prefix, atomuuid)
    def self.atomTypeForToStrings(prefix, atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        return "" if atom.nil?
        "#{prefix}(#{atom["type"]})"
    end
end