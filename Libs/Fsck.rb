
# encoding: UTF-8

class Fsck

    # Fsck::fsckItem(item)
    def self.fsckItem(item)

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
                exit
                nhash = item["nhash"]
                AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(), nhash)
                return
            end

            if item["type"] == "unique-string" then
                return
            end

            if item["type"] == "fs-beacon" then
                return
            end

            raise "(error: c9f718a3-c3ea-4b5a-bf14-679dd1f267a6) cannot fsck #{item}"
        end

        if item["mikuType"] == "Nx101" then
            item["coreDataRefs"].each{|ref|
                Fsck::fsckItem(ref)
            }
            return
        end

        if item["mikuType"] == "NxAvaldi" then
            return
        end

        raise "(error: c9f718a3-c3ea-4b5a-bf14-679dd1f267a6) cannot fsck #{item}"
    end

    # Fsck::fsckAll()
    def self.fsckAll()
        PolyFunctions::allNetworkItems().each{|item|
            Fsck::fsckItem(item)
        }
    end
end

