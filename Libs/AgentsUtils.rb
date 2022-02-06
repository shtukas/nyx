
class AgentsUtils

    # AgentsUtils::atomLandingPresentation(atomuuid)
    def self.atomLandingPresentation(atomuuid)
        atom = Librarian2Objects::getObjectByUUIDOrNull(atomuuid)
        if atom.nil? then
            puts "warning: I could not find the atom for this item (atomuuid: #{atomuuid})"
            LucilleCore::pressEnterToContinue()
        else
            if text = Atoms5::atomPayloadToTextOrNull(atom) then
                puts "text:\n#{text}"
            end
        end
    end

    # AgentsUtils::accessAtom(atomuuid)
    def self.accessAtom(atomuuid)
        atom = Librarian2Objects::getObjectByUUIDOrNull(atomuuid)
        return if atom.nil?
        return if atom["type"] == "description-only"
        atom = Atoms5::accessWithOptionToEditOptionalUpdate(atom)
        return if atom.nil?
        Librarian2Objects::commit(atom)
    end
end