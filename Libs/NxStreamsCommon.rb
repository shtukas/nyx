
class NxStreamsCommon

    # NxStreamsCommon::midpoint()
    def self.midpoint()
        0.5 * (NxTopStreams::endPosition() + NxTailStreams::frontPosition())
    end

    # NxStreamsCommon::dataManagement()
    def self.dataManagement()
        if NxTopStreams::items().size < 3 then
            item1 = NxTailStreams::getFrontElementOrNull()
            item2 = NxTailStreams::getEndElementOrNull()
            [item1, item2]
                .compact
                .each{|item|
                    puts "Promoting item from tail to top: #{JSON.pretty_generate(item)}"
                    newuuid = SecureRandom.uuid
                    newitem = item.clone
                    newitem["uuid"] = newuuid
                    newitem["mikuType"] = "NxTopStream"
                    newitem["position"] = NxStreamsCommon::midpoint()
                    NxTopStreams::commit(newitem)
                    control = NxTopStreams::getItemOfNull(newuuid)
                    if control.nil? then
                        raise "(error: 1731ead9-7ebf-450c-89ba-914c734d4e2c) while processing item: #{JSON.pretty_generate(item)}"
                    end
                    NxTailStreams::destroy(item["uuid"])
                }
        end
    end
end