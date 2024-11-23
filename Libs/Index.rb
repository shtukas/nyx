# encoding: UTF-8

class Index

    # Index::filepath()
    def self.filepath()
        filepath = XCache::filepath("5f777c11-3c76-4769-8d5b-06e128d38150:#{CommonUtils::today()}")
        return filepath if File.exist?(filepath)

        databaseFilepath = filepath
        db = SQLite3::Database.new(databaseFilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table Items (_uuid_ string, _mikuType_ string, _item_ string)", [])
        db.close

        Marbles::filepathEnumeration().each{|filepath|
            item = Marbles::itemOrError(filepath)
            db = SQLite3::Database.new(databaseFilepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.transaction
            db.execute("delete from Items where _uuid_=?", [item["uuid"]])
            db.execute("insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)])
            db.commit
            db.close
        }

        filepath
    end

    # Index::items()
    def self.items()
        items = []
        db = SQLite3::Database.new(Index::filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items", []) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # Index::commitItem(item)
    def self.commitItem(item)
        db = SQLite3::Database.new(Index::filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from Items where _uuid_=?", [item["uuid"]])
        db.execute("insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)])
        db.commit
        db.close
    end

    # Index::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        item = nil
        db = SQLite3::Database.new(Index::filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _uuid_=?", [uuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # Index::delete(uuid)
    def self.delete(uuid)
        db = SQLite3::Database.new(Index::filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from Items where _uuid_=?", [uuid])
        db.commit
        db.close
    end
end
