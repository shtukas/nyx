
# encoding: UTF-8

class Fsck

    # Fsck::fsckItem(referenceuuid, item)
    def self.fsckItem(referenceuuid, item)

        puts "fsck item: #{JSON.pretty_generate(item).green}"

        if item["mikuType"] == "NxCoreDataRef" then

            if item["type"] == "null" then
                return
            end

            if item["type"] == "text" then
                return
            end

            if item["type"] == "url" then
                return
            end

            if item["type"] == "aion-point" then
                nhash = item["nhash"]
                AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(referenceuuid), item["nhash"])
                return
            end

            if item["type"] == "unique-string" then
                return
            end

            raise "(error: 060852c5-227b-4a07-8548-ee3265dd3d2a) cannot fsck #{item}"
        end

        if item["mikuType"] == "NxAionPoints0849" then
            nhash = item["nhash"]
            AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(referenceuuid), item["nhash"])
            return
        end

        if item["mikuType"] == "NxUrl1005" then
            return
        end

        raise "(error: c9f718a3-c3ea-4b5a-bf14-679dd1f267a6) cannot fsck #{item}"
    end

    # Fsck::fsckAll()
    def self.fsckAll()
        Cubes::items().each{|item|
            Fsck::fsckItem(item["uuid"], item)
        }
    end
end

