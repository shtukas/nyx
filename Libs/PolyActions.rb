
class PolyActions

    # PolyActions::program(item)
    def self.program(item)
        if item["mikuType"] == "NxNote" then
            NxNotes::program(item)
        end
        if item["mikuType"] == "NxCoreDataRef" then
            reference = item
            CoreDataRefsNxCDRs::program(node["uuid"], reference)
        end
        if item["mikuType"] == "Nx101" then
            x = Nx101s::program(item)
            if x then
                return x # was selected during a dive
            end
        end
        if item["mikuType"] == "NxAvaldi" then
            x = NxAvaldis::program(item)
            if x then
                return x # was selected during a dive
            end
        end
    end

    # PolyActions::destroy(uuid, message)
    def self.destroy(uuid, message)
        puts "> request to destroy nyx node: #{message}"
        code1 = SecureRandom.hex(2)
        code2 = LucilleCore::askQuestionAnswerAsString("Enter destruction code (#{code1}): ")
        if code1 == code2 then
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction: ") then
                Cubes::destroy(uuid)
                return
            end
        end
    end

    # PolyActions::init(uuid, mikuType)
    def self.init(uuid, mikuType)
        item = {
            "uuid"     => uuid,
            "mikuType" => mikuType
        }
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/nyx/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close
    end

    # PolyActions::setAttribute2(uuid, attrname, attrvalue)
    def self.setAttribute2(uuid, attrname, attrvalue)
        item = PolyFunctions::itemOrNull2(uuid)
        if item.nil? then
            raise "(error 1209) PolyActions::setAttribute2(#{uuid}, #{attrname}, #{attrvalue})"
        end
        item[attrname] = attrvalue
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from Items where _uuid_=?", [uuid]
        db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close
    end
end
