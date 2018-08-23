require 'json'
require 'date'

def nested_fields(obj)
  listing = []
  obj.each_pair do |key, value|
    case value
    when Hash
      nested_fields(value).each do |child|
        listing << [key, child]
      end
    when Array
      array_nested(value).each do |item|
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

def array_nested(array)
  array.map do |item|
    case item
    when Array
      array_nested(item)
    when Hash
      nested_fields(item)
    else
      [item]
    end
  end
end

def is_date?(string)
  date = DateTime.parse(string)
  true if date
rescue
  false
end

def evaluate_fields(fields)
  fields.each do |fld|
    f = fld.flatten
    value = f.pop
    tag = f.last
    if !is_date?(value) && tag !~ /@/
      p f
    end
  end
end

if __FILE__ == $0
  json_lines = ARGV.first
  json_array = open(json_lines).readlines.map.with_index(1) do |line, i|
    if i % 2 == 0
      JSON.load(line)
    end
  end
  fields = nested_fields(json_array.compact.first)
  evaluate_fields(fields)

  # objkt = {a: 1, b: [1,2,3], c: {d: 1, e:2, f: {g: 3}}, h: [1,2,3,[{i:4},{j:5}]]}
  # fields = nested_fields(objkt)
  # fields.each do |f|
  #   p f.flatten[0...-1]
  # end
end
