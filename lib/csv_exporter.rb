require "csv"

# Export a database table to a CSV file
module CsvExporter
    def export_to_csv(table_name)
        # Fetch data from the database table
        data = table_name.classify.constantize.all

        # Define the path for the CSV file
        output_dir = Rails.root.join("csv")
        file_path = File.join(output_dir, "#{table_name}.csv")

        # Delete the existing file if it exists
        File.delete(file_path) if File.exist?(file_path)

        # Open the CSV file in write mode
        CSV.open(file_path, "w") do |csv|
            # Write the header row
            csv << data.first.attributes.keys

            # Write data rows
            data.each do |record|
                csv << record.attributes.values
            end
        end
        
        puts "CSV file #{table_name}.csv has been created successfully"
    end
end