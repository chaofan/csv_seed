module CsvSeed
  class Import
    attr_accessor :name, :tables

    def initialize(name)
      @name = (name || '')
    end

    # thor csv:seed --use points --except Activity ActivityForm
    def run(only, except)
      # TODO 检查参数
      @tables = read_csv
      say_end = []
      models = only.present? ? only : (@tables.keys - (except or []))
      run_tables = @tables.values.select {|t| models.include? t.model}
      # @tables.keep_if {|k| models.include? k}
      puts "\n\n*** run_tables: #{run_tables.map(&:model).join(', ')}\n\n\n"
      ActiveRecord::Base.transaction do
        run_tables.each do |table|
          say_end += table.execute_commands("destroy_all")
        end
        run_tables.each do |table|
          say_end += table.execute_commands
        end
      end

      puts "\n"*3
      say_end.each {|say| puts say}
    end

    def read_csv()
      tables = {}
      current_model = ""
      Dir.glob(Rails.root.join("db","seeds", @name, "*.csv")).each do |csv|
        lines = CSV.read(csv)
        lines.each do |line|
          next if line[0].nil?

          if line[0][0] == "#"
            cmd, *args = *line[0][1..-1].split('#')
            case cmd
            when "model"
              current_model = args.first
              tables[current_model] = Table.new(current_model, tables)
            when "command"
              tables[current_model].commands << {cmd: args.first, args: args[1..-1]}
            when "key"
              tables[current_model].key = args.first
            when "uploader"
              tables[current_model].upload_field_names = args
            end
            next
          end

          # Imported tables should have the 'id' attribute.
          if line[0] == 'id'
            tables[current_model].field_names = line.compact[1..-1]
            next
          end
          # 根据字段表长来截，compact会吞掉内容为空的字段。注意这儿有id。
          tables[current_model].add_record line[0..tables[current_model].field_names.size]
        end
      end
      tables
    end
  end
end
