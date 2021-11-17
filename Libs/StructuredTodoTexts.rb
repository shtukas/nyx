# encoding: UTF-8

class StructuredTodoTexts

    # StructuredTodoTexts::getNoteOrNull(uuid)
    def self.getNoteOrNull(uuid)
        KeyValueStore::getOrNull(nil, "b8b66f79-d776-425c-a00c-d0d1e60d865a:#{uuid}")
    end

    # StructuredTodoTexts::setNote(uuid, text)
    def self.setNote(uuid, text)
        KeyValueStore::set(nil, "b8b66f79-d776-425c-a00c-d0d1e60d865a:#{uuid}", text)
    end
end
