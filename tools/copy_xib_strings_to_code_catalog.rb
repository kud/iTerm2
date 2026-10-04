#!/usr/bin/env ruby
# Usage: tools/copy_xib_strings_to_code_catalog.rb <xib-catalog.xcstrings> <mapping.json> [code-catalog]
#        tools/copy_xib_strings_to_code_catalog.rb --check-roundtrip [code-catalog]
# Example: tools/copy_xib_strings_to_code_catalog.rb sources/Settings/mul.lproj/PreferencePanel.xcstrings tools/xib_strings_maps/pointer.json
#
# Settings panes are moving from PreferencePanel.xib into code. Their strings
# are keyed by xib object ID in the xib catalog (e.g. "6408.title"). This copies
# each mapped entry, translations included, to a symbolic key in the code
# catalog (xcstrings/Localizable.xcstrings) so no language regresses to
# English. The mapping file is a JSON array of objects with "from" (xib key),
# "to" (code key), "comment" and "english" (expected English value).
# Run `make extract-strings` afterwards to renormalise.
#
# The code catalog is re-serialized exactly the way Xcode writes it (2-space
# indentation, "key" : value with spaces around the colon, minimal JSON
# escaping), so untouched entries come back byte-identical. --check-roundtrip
# verifies that: it parses and re-serializes the code catalog without changes
# and exits 0 only if the output is byte-identical to the input.

require 'json'

DEFAULT_CODE_CATALOG = 'xcstrings/Localizable.xcstrings'

def main
  args = ARGV.dup
  if args.delete('--check-roundtrip')
    if args.length > 1
      puts "Usage: #{$0} --check-roundtrip [code-catalog]"
      exit 1
    end
    exit(check_roundtrip(args.first || DEFAULT_CODE_CATALOG) ? 0 : 1)
  end

  if args.length < 2 || args.length > 3
    puts "Usage: #{$0} <xib-catalog.xcstrings> <mapping.json> [code-catalog, default #{DEFAULT_CODE_CATALOG}]"
    exit 1
  end

  xib_path, mapping_path, code_path = args
  code_path ||= DEFAULT_CODE_CATALOG

  xib = parse_json_file(xib_path, 'xib catalog')
  mapping = parse_json_file(mapping_path, 'mapping')
  code_text = read_file(code_path, 'code catalog')
  code = parse_json(code_text, code_path)
  exit 1 if xib.nil? || mapping.nil? || code.nil?

  xib_strings = xib['strings'] || {}
  code_strings = code['strings']
  if code_strings.nil?
    $stderr.puts "Error: #{code_path} has no \"strings\" object"
    exit 1
  end

  mapping.each do |entry|
    from = entry['from']
    to = entry['to']
    xib_entry = xib_strings[from]
    if xib_entry.nil?
      $stderr.puts "Error: #{from.inspect} is missing from #{xib_path}"
      exit 1
    end
    english = english_value(xib_entry)
    if english != entry['english']
      $stderr.puts "Error: English value of #{from.inspect} differs from the mapping:"
      $stderr.puts "  xib:     #{english.inspect}"
      $stderr.puts "  mapping: #{entry['english'].inspect}"
      exit 1
    end
    existing = code_strings[to]
    if !existing.nil? && existing['localizations'] != xib_entry['localizations']
      $stderr.puts "Error: #{to.inspect} already exists in #{code_path} with different localizations"
      exit 1
    end
    code_strings[to] = {
      'comment' => entry['comment'],
      'extractionState' => 'extracted_with_value',
      'localizations' => xib_entry['localizations'],
    }
  end

  # The catalog is already in String#<=> order, so sorting slots the new keys in
  # and leaves every existing key where it was.
  sorted = {}
  code_strings.keys.sort.each do |key|
    sorted[key] = code_strings[key]
  end
  code['strings'] = sorted

  write_file(code_path, serialize(code, code_text))
  puts "Updated #{code_path}"
end

def parse_json_file(path, label)
  parse_json(read_file(path, label), path)
end

def read_file(path, label)
  File.read(path, encoding: 'utf-8')
rescue SystemCallError => e
  $stderr.puts "Error: cannot read #{label} #{path}: #{e.message}"
  exit 1
end

def parse_json(text, path)
  return nil if text.nil?
  JSON.parse(text)
rescue JSON::ParserError => e
  $stderr.puts "Error: cannot parse #{path}: #{e.message}"
  nil
end

def write_file(path, text)
  File.write(path, text)
rescue SystemCallError => e
  $stderr.puts "Error: cannot write #{path}: #{e.message}"
  exit 1
end

def english_value(xib_entry)
  localizations = xib_entry['localizations']
  return nil unless localizations.is_a?(Hash)
  en = localizations['en']
  return nil unless en.is_a?(Hash)
  unit = en['stringUnit']
  return nil unless unit.is_a?(Hash)
  unit['value']
end

def check_roundtrip(path)
  text = read_file(path, 'code catalog')
  catalog = parse_json(text, path)
  return false if catalog.nil?
  roundtripped = serialize(catalog, text)
  if roundtripped == text
    puts "Roundtrip clean: #{path}"
    true
  else
    $stderr.puts "Error: re-serializing #{path} without changes is not byte-identical"
    false
  end
end

# Serialize exactly like Xcode: 2-space indentation, "key" : value with a
# space on both sides of the colon, non-ASCII and "/" left alone, and only
# what JSON requires escaped.
def serialize(value, original_text, indent = '')
  case value
  when Hash
    if value.empty?
      return empty_object_style(original_text)
    end
    lines = ['{']
    value.each_with_index do |(key, element), index|
      comma = index < value.size - 1 ? ',' : ''
      lines << "#{indent}  #{escape_string(key)} : #{serialize(element, original_text, indent + '  ')}#{comma}"
    end
    lines << "#{indent}}"
    lines.join("\n")
  when Array
    if value.empty?
      return '[]'
    end
    lines = ['[']
    value.each_with_index do |element, index|
      comma = index < value.size - 1 ? ',' : ''
      lines << "#{indent}  #{serialize(element, original_text, indent + '  ')}#{comma}"
    end
    lines << "#{indent}]"
    lines.join("\n")
  when String
    escape_string(value)
  when true, false
    value.inspect
  when nil
    'null'
  when Numeric
    value.to_s
  else
    raise "Cannot serialize #{value.class}"
  end + trailing_newline(original_text, indent)
end

def trailing_newline(original_text, indent)
  return '' unless indent.empty?
  original_text.end_with?("\n") ? "\n" : ''
end

def empty_object_style(original_text)
  return "{\n\n}" if original_text.include?("{\n\n}")
  '{}'
end

def escape_string(string)
  out = +'"'
  string.each_char do |char|
    case char
    when '"' then out << '\\"'
    when '\\' then out << '\\\\'
    when "\n" then out << '\\n'
    when "\t" then out << '\\t'
    when "\r" then out << '\\r'
    when "\b" then out << '\\b'
    when "\f" then out << '\\f'
    else
      ordinal = char.ord
      if ordinal < 0x20
        out << format('\\u%04x', ordinal)
      else
        out << char
      end
    end
  end
  out << '"'
  out
end

main
