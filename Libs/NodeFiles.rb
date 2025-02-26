
class NodeFiles

    # NodeFiles::newFilePath()
    def self.newFilePath()
        "/Users/pascal/Galaxy/DataHub/Nyx/data/nodes/2025/2025-02/#{CommonUtils::timeStringL22()}.nyxnode-4be8.txt"
    end

    # NodeFiles::attributesToNodeFileText(uuid, description, datetime, linkeduuids, tags, notes, payloads)
    def self.attributesToNodeFileText(uuid, description, datetime, linkeduuids, tags, notes, payloads)
        [
            "uuid: #{uuid}",
            "description: #{description}",
            "datetime: #{datetime}",
            linkeduuids.map{|uuid|
                "linkeduuid: #{uuid}"
            },
            tags.map{|tag|
                "tag: #{tag}"
            },
            notes.map{|note|
                "note: #{JSON.generate(note)}"
            },
            payloads.map{|payload|
                "payload: #{JSON.generate(payload)}"
            },
        ]
        .flatten
        join("\n")
    end

    # NodeFiles::issueNewFile(uuid, description, datetime, linkeduuids, tags, notes, payloads)
    def self.issueNewFile(uuid, description, datetime, linkeduuids, tags, notes, payloads)
        filepath = NodeFiles::newFilePath()
        text = NodeFiles::attributesToNodeFileText(uuid, description, datetime, linkeduuids, tags, notes, payloads)
        File.open(filepath, "w"){|f| f.puts(text) }
    end
end
