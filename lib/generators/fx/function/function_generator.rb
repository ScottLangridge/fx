require "rails/generators"
require "rails/generators/active_record"

module Fx
  module Generators
    class FunctionGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      def create_functions_directory
        unless function_definition_path.exist?
          empty_directory(function_definition_path)
        end
      end

      def create_function_definition
        create_file definition.path
      end

      def create_migration_file
        if updating_existing_function?
          migration_template(
            "db/migrate/update_function.erb",
            "db/migrate/update_#{file_name}_to_version_#{version}.rb"
          )
        else
          migration_template(
            "db/migrate/create_function.erb",
            "db/migrate/create_#{file_name}.rb"
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @_previous_version ||= Dir.entries(function_definition_path).
            map { |name| version_regex.match(name).try(:[], "version").to_i }.
            max
        end

        def version
          @_version ||= previous_version.next
        end

        def migration_class_name
          if updating_existing_function?
            "Update#{class_name}ToVersion#{version}"
          else
            super
          end
        end

        def formatted_name
          if singular_name.include?(".")
            "\"#{singular_name}\""
          else
            ":#{singular_name}"
          end
        end
      end

      private

      def function_definition_path
        @_function_definition_path ||= Rails.root.join(*%w(db functions))
      end

      def version_regex
        /\A#{file_name}_v(?<version>\d+)\.sql\z/
      end

      def updating_existing_function?
        previous_version > 0
      end

      def definition
        Fx::Definition.new(name: file_name, version: version)
      end
    end
  end
end
