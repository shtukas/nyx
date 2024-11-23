# encoding: UTF-8

class Interface

    # Interface::itemInit(uuid)
    def self.itemInit(uuid)
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/Marbles/#{SecureRandom.hex}.nyx17"
        Marbles::initiate(filepath, uuid)
        item = {
            "uuid" => uuid,
            "mikuType" => "Sx0138"
        }
        Index::commitItem(item)
    end

    # Interface::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Marbles::itemOrNull(uuid)
    end

    # Interface::items()
    def self.items()
        Index::items()
    end

    # Interface::mikuType(mikuType)
    def self.mikuType(mikuType)
        items = []
        db = SQLite3::Database.new(Index::filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # Interface::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)

        # marble update:
        Marbles::updateAttribute2(uuid, attrname, attrvalue)

        # Index update:
        item = Index::itemOrNull(uuid)
        if item then
            item[attrname] = attrvalue
            Index::commitItem(item)
        end
    end

    # Interface::destroy(uuid)
    def self.destroy(uuid)
        Index::delete(uuid)
        Marbles::destroy2(uuid)
    end
end
