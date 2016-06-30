# encoding: utf-8

module Backup
  module Database
    class Neo4j < Base
      class Error < Backup::Error; end

      ##
      # Name of the database that needs to get dumped.
      # To dump all databases, set this to `:all` or leave blank.
      # +username+ must be a PostgreSQL superuser to run `pg_dumpall`.
      #attr_accessor :name

      ##
      # Credentials for the specified database
      #attr_accessor :username, :password

      ##
      # If set the pg_dump(all) command is executed as the given user
      #attr_accessor :sudo_user

      ##
      # Connectivity options
      attr_accessor :host, :port

      attr_accessor :bin_path

      # :full or :incremental
      attr_accessor :mode

      ##
      # Additional "pg_dump" or "pg_dumpall" options
      attr_accessor :additional_options

      def initialize(model, database_id = nil, &block)
        super
        instance_eval(&block) if block_given?

        @port ||= 6362
        @host ||= 'localhost'
        @mode ||= :full
      end

      ##
      # Performs the pgdump command and outputs the dump file
      # in the +dump_path+ using +dump_filename+.
      #
      #   <trigger>/databases/PostgreSQL[-<database_id>].sql[.gz]
      def perform!
        super
        backup
        log!(:finished)
      end

      def backup
        dst_path = File.join(dump_path, dump_filename)
        cmd = "#{ bin_path }/neo4j-backup -#{ mode } -host #{ host } -to #{ dst_path }"
        run(cmd)
        model.compressor.compress_with do |command, ext|
          run("#{ command } -cr '#{ dst_path }' > '#{ dst_path + ext }'")
        end if model.compressor
      end
    end
  end
end
