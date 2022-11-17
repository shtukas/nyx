class NxItemResolver1

    # NxItemResolver1::make(uuid, mikuType)
    def self.make(uuid, mikuType)
        {
            "mikuType" => "NxItemResolver1",
            "uuid"     => uuid,
            "type"     => mikuType
        }
    end

    # NxItemResolver1::getItemOrNull(resolver)
    def self.getItemOrNull(resolver)

        if resolver["type"] == "NxTodo" then
            return NxTodos::getItemOrNull(resolver["uuid"])
        end

        if resolver["type"] == "Wave" then
            return Waves::getOrNull(resolver["uuid"])
        end

        raise "(error: 1aa8d612-6a95-43a2-8515-ab40a60ad64d) unsupported type in #{JSON.pretty_generate(resolver)}"
    end
end
