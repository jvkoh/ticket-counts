# Ticket Count Scripts

Uses `ruby 2.4.5`

### Usage

`ruby ticket_formatter <input_file> <output_files_prefix>`

### Output

Two files:
- "<output_prefix>_days_from_on_sale.tsv"
  - a TSV where every column represents a certain number of days from the on sale date
- "<output_prefix>_days_from_show.tsv"
  - a TSV where every column represents a certain number of days from the show date

### Input File Format

**All Dates must be formatted:** `MM/DD/YYYY`

First row is the header row, all header values must either be **dates** or **static keys**.  Below is a list of acceptable **static keys**.
- show_date
- on_sale_date
- location_string
- venue
- sellable
- final

All of the remaining rows should represent shows.  They shoud have the corresponding static key values, and for any date columns they should have the ticket count.

**NOTE:** even static `show_date` and `on_sale_date` values must be correctly date formatted, as they are used for calculations.
