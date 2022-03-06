
# encoding: UTF-8

class Catalyst

    # Catalyst::fsck()
    def self.fsck()
        Anniversaries::anniversaries().each{|item|
            puts Anniversaries::toString(item)
        }
        Nx31::mikus().each{|item|
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            raise "[error: 23074570-475f-45b6-90a7-786256dfface, #{item}]" if atom.nil?
            status = Librarian5Atoms::fsck(atom)
            raise "[error: d4f39eb1-7a3b-4812-bb99-7adeb9d8c37c, #{item}, #{atom}]" if !status
        }
        TxCalendarItems::items().each{|item|
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            raise "[error: b3fde618-5d36-4f50-b1dc-cbf29bc4d61e, #{item}]" if atom.nil?
            status = Librarian5Atoms::fsck(atom)
            raise "[error: 95cc8958-897f-4a44-b986-9780c71045fd, #{item}, #{atom}]" if !status
        }
        TxDateds::items().each{|item|
            puts TxDateds::toString(item)
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            raise "[error: 291a7dd7-dc6d-4ab0-af48-50e67b455cb8, #{item}]" if atom.nil?
            status = Librarian5Atoms::fsck(atom)
            raise "[error: d9154d97-9bf6-43bb-9517-12c8a9d34509, #{item}, #{atom}]" if !status
        }
        TxDrops::mikus().each{|item|
            puts TxDrops::toString(item)
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            raise "[error: e55d3f91-78d7-4819-a49a-e89be9b301bb, #{item}]" if atom.nil?
            status = Librarian5Atoms::fsck(atom)
            raise "[error: 4b86d0a7-a7b1-487d-95ab-987864c949f6, #{item}, #{atom}]" if !status
        }
        TxFloats::items().each{|item|
            puts TxFloats::toString(item)
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            raise "[error: f5e1688f-3c5a-4da6-a751-5bbb4280844d, #{item}]" if atom.nil?
            status = Librarian5Atoms::fsck(atom)
            raise "[error: 0dbec1f7-6c22-4fa2-b288-300bb95b8bba, #{item}, #{atom}]" if !status
        }
        TxTodos::items().each{|item|
            puts TxTodos::toString(item)
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            if atom.nil? then
                TxTodos::access(item)
                #raise "[error: 04f4e88a-fe02-426f-bf4d-4d4c8794d16c, #{item}]"
                next
            end
            status = Librarian5Atoms::fsck(atom)
            raise "[error: bf252b78-6341-4715-ae52-931f3eed0d9d, #{item}, #{atom}]" if !status   
        }
        Waves::items().each{|item|
            puts Waves::toString(item)
            atomuuid = item["atomuuid"]
            atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
            raise "[error: 375b7330-ce92-456a-a348-989718a7726d, #{item}]" if atom.nil?
            status = Librarian5Atoms::fsck(atom)
            raise "[error: cfda30da-73a6-4ad9-a3e4-23ed1a2cbc76, #{item}, #{atom}]" if !status
        }
    end
end
