
# encoding: UTF-8

class Nx112

    # Nx112::carrierAccess(item)
    def self.carrierAccess(item)
        return if item.nil?
        puts "Nx112::carrierAccess(item): #{PolyFunction::toString(item)}"
        Nx112::targetAccess(item["nx112"])
    end

    # Nx112::targetAccess(uuid)
    def self.targetAccess(uuid)
        return if uuid.nil?
        target = DxF1::getProtoItemOrNull(uuid)
        if target.nil? then
            puts "I the target object (uuid: #{uuid}) doesn't exists."
            LucilleCore::pressEnterToContinue()
            return
        end
        PolyAction::access(target)
    end
end
