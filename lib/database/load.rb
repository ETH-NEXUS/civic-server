module Database
  class Load < AuthenticatedCommand
    def self.command(file = Rails.configuration.data_dump_path)
      "psql -v ON_ERROR_STOP=1 -f #{file}"
    end
  end
end
