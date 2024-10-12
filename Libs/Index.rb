# encoding: UTF-8

class Index

    # Index::filepath()
    def self.filepath()
        XCache::filepath("5f777c11-3c76-4769-8d5b-06e128d38150:#{CommonUtils::today()}")
    end

    # Index::buildIndex(databaseFilepath)
    def self.buildIndex(databaseFilepath)

        if File.exist?(databaseFilepath) then
            FileUtils.rm(databaseFilepath)
        end

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
    end

    # Index::filepathWithCertainty()
    def self.filepathWithCertainty()
        filepath = Index::filepath()
        if File.exist?(filepath) then
            return filepath
        end
        puts "Could not find the index, rebuilding...".yellow
        sleep 1
        Index::buildIndex(filepath)
        filepath
    end

    # Index::rebuildIndex()
    def self.rebuildIndex()
        Index::buildIndex(Index::filepath())
    end

    # Index::items()
    def self.items()
        items = []
        db = SQLite3::Database.new(Index::filepathWithCertainty())
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
        db = SQLite3::Database.new(Index::filepathWithCertainty())
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
        db = SQLite3::Database.new(Index::filepathWithCertainty())
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
        db = SQLite3::Database.new(Index::filepathWithCertainty())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from Items where _uuid_=?", [uuid])
        db.commit
        db.close
    end
end
