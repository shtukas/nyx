
# encoding: UTF-8

class Fsck

    # Fsck::fsckItem(item)
    def self.fsckItem(item)
        puts JSON.pretty_generate(item)
        if item["uuid"].nil? then
            puts item
            raise "Project item has no uuid"
        end
        if item["creationtime"].nil? then
            puts item
            raise "Project item has no creationtime"
        end
        if item["target"].nil? then
            puts item
            raise "Project item has no target"
        end
        target = item["target"]
        CatalystStandardTarget::fsckTarget(target)
    end

    # Fsck::fsckProject(project)
    def self.fsckProject(project)
        puts JSON.pretty_generate(project)
        if project["uuid"].nil? then
            puts project
            raise "Project has no uuid"
        end
        if project["creationtime"].nil? then
            puts project
            raise "Project has no creationtime"
        end
        if project["description"].nil? then
            puts project
            raise "Project has no description"
        end
        if project["schedule"].nil? then
            puts project
            raise "Project has no schedule"
        end
        items = Items::getItemsByCreationTime(project["uuid"])
        items.each{|item|
            Fsck::fsckItem(item)
        }
    end
end
