require 'pp'
require 'date'

class TicketFormatter

  STATIC_KEYS = [
    'show_date',
    'on_sale_date',
    'location_string',
    'venue',
    'sellable',
    'final',
  ]

  INPUT_DATE_FORMAT = "%m/%d/%Y"

  def initialize
    @header_object = {} # { static_key: index, ... }
    @header_row = []
    @data_rows = []
    @formatted_data = []
  end

  def parse_date(date)
    Date.strptime(date, INPUT_DATE_FORMAT)
  end

  # Parses whole TSV file as a string
  def parse_input_string(tsv_string)
    rows = tsv_string.split(/\r\n/)
    row_raw_data = rows.map do |row|
      row.gsub!(/"/, '')
      row.split("\t")
    end

    @header_row = row_raw_data[0]
    @data_rows = row_raw_data[1..-1]

    @header_row.each.with_index do |col_key, i|
      if STATIC_KEYS.include?(col_key)
        @header_object[col_key] = i
      else
        date = parse_date(col_key)
        @header_row[i] = date
      end
    end

    format_data
  end

  def format_data
    @data_rows.each.with_index do |row, i|
      formatted_object = {}
      days_from_show_values = []
      days_from_on_sale_values = []

      on_sale_date = parse_date(row[@header_object['on_sale_date']])
      show_date = parse_date(row[@header_object['show_date']])

      row.each.with_index do |col_val, i|
        if STATIC_KEYS.include?(@header_row[i])
          # Add static values to object
          formatted_object[@header_row[i]] = col_val

        else # otherwise format ticket sale value
          next if col_val == "NU" # Skip "No Update" rows
          ticket_sales = col_val.gsub(/,/, '').to_i # Remove commas from number strings like 5,000
          col_date = @header_row[i] # Get date for this column

          days_from_show = (show_date - col_date).to_i
          days_from_on_sale = (col_date - on_sale_date).to_i

          days_from_show_values[days_from_show] = ticket_sales if days_from_show >= 0
          days_from_on_sale_values[days_from_on_sale] = ticket_sales if days_from_on_sale >= 0
        end
      end

      formatted_object[:days_from_show] = days_from_show_values
      formatted_object[:days_from_on_sale] = days_from_on_sale_values
      @formatted_data << formatted_object
    end
  end

  def days_from_on_sale_formatted
    max_days = @formatted_data.map { |row| row[:days_from_on_sale].length }.max
    header = STATIC_KEYS + (0..max_days).to_a
    rows = @formatted_data.map do |row|
      STATIC_KEYS.map { |key| row[key] } + row[:days_from_on_sale]
    end
    [header].concat(rows)
  end

  def days_from_show_formatted
    max_days = @formatted_data.map { |row| row[:days_from_show].length }.max
    header = STATIC_KEYS + (0..max_days).to_a
    rows = @formatted_data.map do |row|
      STATIC_KEYS.map { |key| row[key] } + row[:days_from_show]
    end
    [header].concat(rows)
  end

  def meta_formatted
    header = STATIC_KEYS
    rows = @formatted_data.map do |row|
      header.map { |col| row[col] }
    end
    [header].concat(rows)
  end

end



##############
### SCRIPT ###
##############

if __FILE__ == $0
  require 'csv'

  if ARGV.length < 1
    puts "Usage: ticket_formatter.rb <input_filename> [output_prefix]"
    throw "Not enough arguments, see usage"
  end

  input_filename = ARGV[0]
  output_prefix = ARGV[1] || ''

  input_string = ''
  tf = TicketFormatter.new

  begin
    input_string = File.read(input_filename)
  rescue => e
    throw "Error opening ticket count tsv file: #{e.message}"
  end

  tf.parse_input_string(input_string)

  CSV.open("#{output_prefix}_days_from_on_sale.tsv", "wb", col_sep: "\t") do |tsv|
    tf.days_from_on_sale_formatted.each do |row|
      tsv << row
    end
  end

  CSV.open("#{output_prefix}_days_from_show.tsv", "wb", col_sep: "\t") do |tsv|
    tf.days_from_show_formatted.each do |row|
      tsv << row
    end
  end
end
