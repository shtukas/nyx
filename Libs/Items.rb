# encoding: UTF-8

=begin

Updates:
    {
        "updateType": "init",
        "uuid"       : String,
        "mikuType"   : String
    }

    {
      "updateType": "set-attribute",
      "uuid"       : String,
      "attrname"   : String,
      "attrvalue"  : String
    }

    {
        "updateType": "destroy",
        "uuid"       : String,
    }
=end

class Items

    # ----------------------------------------
    # Core

    # Items::commitItemToDatabase(item)
    def self.commitItemToDatabase(item)
        filepath = "#{Config::pathToData()}/Items/20240607-195008-183664.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from Items where _uuid_=?", [item["uuid"]])
        db.execute("insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)])
        db.commit
        db.close
    end

    # Items::itemFromDatabaseOrNull(uuid)
    def self.itemFromDatabaseOrNull(uuid)
        item = nil
        db = SQLite3::Database.new("#{Config::pathToData()}/Items/20240607-195008-183664.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _uuid_=?", [uuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # Items::deleteItemInDatabase(uuid)
    def self.deleteItemInDatabase(uuid)
        filepath = "#{Config::pathToData()}/Items/20240607-195008-183664.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from Items where _uuid_=?", [uuid])
        db.commit
        db.close
    end

    # Items::issueUpdate(update)
    def self.issueUpdate(update)
        filepath = "#{Config::pathToData()}/Items/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(update)) }
    end

    # Items::attributesJournal()
    def self.attributesJournal()
        LucilleCore::locationsAtFolder("#{Config::pathToData()}/Items")
            .select{|location| location[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Items::upgradeItemsWithAttributesJournal(items, journal)
    def self.upgradeItemsWithAttributesJournal(items, journal)
        journal.each{|update|

            if update["updateType"] == "init" then
                item = {
                    "uuid" => update["uuid"],
                    "mikuType" => update["mikuType"]
                }
                items = items + [item]
            end

            if update["updateType"] == "set-attribute" then
                uuid = update["uuid"]
                attrname = update["attrname"]
                attrvalue = update["attrvalue"]
                items = items.map{|item|
                    if item["uuid"] == uuid then
                        item[attrname] = attrvalue
                    end
                    item
                }
            end

            if update["updateType"] == "destroy" then
                uuid = update["uuid"]
                items = items.select{|item| item["uuid"] != uuid}
            end
        }
        items
    end

    # ----------------------------------------
    # Interface

    # Items::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        update = {
            "updateType" => "init",
            "uuid" => uuid,
            "mikuType" => mikuType
        }
        Items::issueUpdate(update)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        item = nil
        db = SQLite3::Database.new("#{Config::pathToData()}/Items/20240607-195008-183664.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _uuid_=?", [uuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        return nil if item.nil?
        Items::upgradeItemsWithAttributesJournal([item], Items::attributesJournal()).first
    end

    # Items::items()
    def self.items()
        items = []
        db = SQLite3::Database.new("#{Config::pathToData()}/Items/20240607-195008-183664.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items", []) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        Items::upgradeItemsWithAttributesJournal(items, Items::attributesJournal())
    end

    # Items::mikuType(mikuType)
    def self.mikuType(mikuType)
        items = []
        db = SQLite3::Database.new("#{Config::pathToData()}/Items/20240607-195008-183664.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        Items::upgradeItemsWithAttributesJournal(items, Items::attributesJournal())
    end

    # Items::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        update = {
            "updateType" => "set-attribute",
            "uuid" => uuid,
            "attrname" => attrname,
            "attrvalue" => attrvalue
        }
        Items::issueUpdate(update)
    end

    # Items::destroy(uuid)
    def self.destroy(uuid)
        update = {
            "updateType" => "destroy",
            "uuid" => uuid,
        }
        Items::issueUpdate(update)
    end

    # Items::processJournal()
    def self.processJournal()
        LucilleCore::locationsAtFolder("#{Config::pathToData()}/Items")
            .select{|location| location[-5, 5] == ".json" }
            .map{|filepath|
                update = JSON.parse(IO.read(filepath))

                puts JSON.pretty_generate(update).yellow

                if update["updateType"] == "init" then
                    item = {
                        "uuid" => update["uuid"],
                        "mikuType" => update["mikuType"]
                    }
                    Items::commitItemToDatabase(item)
                end

                if update["updateType"] == "set-attribute" then
                    uuid = update["uuid"]
                    attrname = update["attrname"]
                    attrvalue = update["attrvalue"]
                    item = Items::itemFromDatabaseOrNull(uuid)
                    if item then
                        item[attrname] = attrvalue
                        Items::commitItemToDatabase(item)
                    end
                end

                if update["updateType"] == "destroy" then
                    uuid = update["uuid"]
                    Items::deleteItemInDatabase(uuid)
                end

                FileUtils.rm(filepath)
            }
    end
end
