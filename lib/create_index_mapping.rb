require 'json'
require 'date'
require 'redis'

class DateTime
  class << self
    def is_date?(string)
      date = self.parse(string)
      true if date
    rescue
      false
    end
  end
end

module OmicsMetadataFields
  class << self
    def extract_fields(json_lines_path, redis_client)
      File.open(json_lines_path).each_line.each_with_index do |json, i|
        if i.odd?
          add_field_to_redis(json, redis_client)
        end
      end
    end

    def add_field_to_redis(json, redis_client)
      redis_client.pipelined do
        extract(JSON.load(json)).each do |field|
          redis_client.sadd("fields", field)
        end
      end
    end

    def unique_fields(redis_client)
      redis_client.sort("fields", order: "asc alpha")
    end

    def extract(object)
      evaluate(field_listing(object))
    end

    def field_listing(object)
      listing = []
      object.each_pair do |key, value|
        case value
        when Hash
          field_listing(value).each do |child|
            listing << [key, child]
          end
        when Array
          array_of_listing(value).each do |item|
            item.each do |i|
              listing << [key, i]
            end
          end
        else
          listing << [key, value]
        end
      end
      listing
    end

    def array_of_listing(array)
      array.map do |item|
        case item
        when Array
          array_of_listing(item)
        when Hash
          field_listing(item)
        else
          [item]
        end
      end
    end

    def evaluate(fields)
      collection = fields.map do |field|
        f = field.flatten
        value = f.pop
        tag = f.last
        if !DateTime.is_date?(value) && tag !~ /@/
          f.join(".")
        end
      end
      collection.compact.uniq
    end
  end
end

module OmicsMetadataIndexMapping
  class << self
    def mapping(fields)
      analyzer.merge(properties(fields))
    end

    def analyzer
      {
        settings: {
          analysis: {
            analyzer: {
              ngram_analyzer: {
                tokenizer: "ngram_tokenizer"
              }
            },
            tokenizer: {
              ngram_tokenizer: {
                type: "ngram",
                min_gram: 3,
                max_gram: 3,
                token_chars: [
                  "letter",
                  "digit"
                ]
              }
            }
          }
        }
      }
    end

    def fields_index_setting(fields)
      setting = {}
      fields.each do |field|
        setting[field] = {
          type: "string",
          analyzer: "ngram_tokenizer"
        }
      end
      setting
    end

    def properties(fields)
      {
        mappings: {
          metadata: {
            properties: fields_index_setting(fields)
          }
        }
      }
    end
  end
end

if __FILE__ == $0
  redis = Redis.new(host: "redis", port: 6379, driver: :hiredis)

  json_lines_path = ARGV.first
  OmicsMetadataFields.extract_fields(json_lines_path, redis)
  fields = OmicsMetadataFields.unique_fields(redis)

  puts OmicsMetadataIndexMapping.mapping(fields)
end
