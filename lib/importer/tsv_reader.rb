require 'csv'

module Importer
  class TsvReader
    def initialize(file_path, row_adaptor, delimiter = "\t", headers = true)
      raise "File #{file_path} doesn't exist!" unless File.exists?(file_path)
      file = File.open(file_path, 'r')
      @csv = CSV.new(file, col_sep: delimiter, headers: headers, quote_char: "\x00")
      @row_adaptor = row_adaptor
    end

    def import!
      skipped_rows = 0
      ActiveRecord::Base.transaction do
        @csv.each do |row|
          if @row_adaptor.valid_row?(row)
            @row_adaptor.create_entities_for_row(row)
          else
            skipped_rows += 1
          end
        end
      end
      puts "Import Complete, skipped #{skipped_rows} invalid rows."
    end
  end
end