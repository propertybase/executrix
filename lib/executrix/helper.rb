require 'csv'

module Executrix
  module Helper
    extend self

    CSV_OPTIONS = {
      col_sep: ',',
      quote_char: '"',
      force_quotes: true,
    }

    def records_to_csv records
      file_mock = StringIO.new
      csv_client = CSV.new(file_mock, CSV_OPTIONS)
      all_headers = []
      all_rows = []
      records.each do |hash|
        row = CSV::Row.new([],[],false)
        to_store = hash.inject({}) do |h, (k, v)|
          if v == nil || v == '' || v == []
            h[k] = '#N/A'
          else
            h[k] = v.class == Array ? v.join(';') : v
          end
          h
        end
        row << to_store
        all_headers << row.headers
        all_rows << row
      end
      all_headers.flatten!.uniq!
      csv_client << all_headers
      all_rows.each do |row|
        csv_client << row.fields(*all_headers)
      end
      file_mock.string
    end

    def fetch_instance_from_server_url server_url
      before_sf = server_url[/^https?:\/\/(.+)\.salesforce\.com/, 1]
      before_sf.gsub(/-api$/,'')
    end

    def attachment_keys records
      records.map do |record|
        record.select do |key, value|
          value.class == File
        end.keys
      end.flatten.uniq
    end

    def transform_values! records, keys
      keys.each do |key|
        records.each do |record|
          file_handle = record[key]
          if file_handle
            file_path = File.absolute_path(file_handle)
            record
              .merge!({
                key => Executrix::Helper.absolute_to_relative_path(file_path,'#')
              })
            yield file_path if block_given?
          end
        end
      end
    end

    def absolute_to_relative_path input, replacement
      input.gsub(/(^C:[\/\\])|(^\/)/,replacement)
    end

    def normalize_csv res
      res.gsub(/\n\s+/, "\n")
    end

    def split_csv_line line
      # replace empty columns with a temp value.  Do it twice
      line.gsub!(/,\"\",/, ",\"\x05\",")
      line.gsub!(/,\"\",/, ",\"\x05\",")
      # catch them at the end of the line!
      line.gsub!(/,\"\"\n/, ",\"\x05\"\n")
      # replace ludicrous triple quotes with single
      line.gsub!(/\"\"\"/, "\"")
      # replace double quotes (not indicating empty column) with a temp value
      line.gsub!("\"\"", "\x06")
      line.chomp!("\"\n")
      line.sub!("\"", "") #first occurence at beginning of string.

      line.split("\",\"").map do |col|
        col.gsub!(/\x05/, "")
        col.gsub!(/\x06/, "\"")
        col
      end
    end

    # determines if a line is actually complete, or if it has false line ending caused by bad CSV format from SF
    # complete lines end with 1 of the following
    # 1: "\"\n" in the typical case
    # 2: ",\"\"\n" when the value for the last column of the line is empty.
    # 3: "\n" preceded by an ODD number of "\"", and no comma.  An even number usually indicates escaped strings in the actual text value.
    #valid line endings are either ()
    def valid_line_ending?(string)
      #match optional /,/ followed by 1 or more /\"/, followed by /\n/

      ending = string.match(/(\,)?(\"){1,}\n/)[0]
      return false unless string.end_with?(ending)
      
      ending.count("\"").odd? || ending.count(",") == 1
    end

    #just add an extra temp character to prevent line splitting.
    def escape_line_ending(string)
      string.gsub!("\"\n", "\"\x05\n")
    end

    def parse_csv csv_string
      CSV.parse(csv_string, headers: true).map{|r| r.to_hash}
    end

    # Salesforce gives us is comma-delimited text, not strictly CSV format.  
    def csv_to_hash line, headers
      Hash[headers.zip(split_csv_line(line))]
    end
  end
end
