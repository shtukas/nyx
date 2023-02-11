
class NxList

    # NxList::midpoint()
    def self.midpoint()
        0.5 * (NxHeads::endPosition() + NxTails::frontPosition())
    end

    # NxList::dataManagement()
    def self.dataManagement()
        if NxHeads::items().size < 3 then
            item1 = NxTails::getFrontElementOrNull()
            item2 = NxTails::getEndElementOrNull()
            [item1, item2]
                .compact
                .each{|item|
                    puts "Promoting item from tail to top: #{JSON.pretty_generate(item)}"
                    newuuid = SecureRandom.uuid
                    newitem = item.clone
                    newitem["uuid"] = newuuid
                    newitem["mikuType"] = "NxHead"
                    newitem["position"] = NxList::midpoint()
                    NxHeads::commit(newitem)
                    control = NxHeads::getItemOfNull(newuuid)
                    if control.nil? then
                        raise "(error: 1731ead9-7ebf-450c-89ba-914c734d4e2c) while processing item: #{JSON.pretty_generate(item)}"
                    end
                    NxTails::destroy(item["uuid"])
                }
        end
    end
end