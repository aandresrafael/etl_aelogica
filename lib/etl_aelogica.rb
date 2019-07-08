require "etl_aelogica/version"
require 'light-service'
require 'csv'

module EtlAelogica
  class Error < StandardError; end

  # Organizer
  class UserEtl
    extend LightService::Organizer

    def self.call(args = {})
      with(args).reduce(actions)
    end

    def self.actions
      [
        PullsDataFromCSV,
        LoadsData
      ]
    end
  end

  #Action
  class PullsDataFromCSV
    extend LightService::Action
    promises :retrieved_items

    executed do |context|
      context.retrieved_items = CSV.open(File.join(File.dirname(__FILE__), '../data/users.csv'))
    end
  end

  #Action

  class LoadsData
    extend LightService::Action
    expects :retrieved_items

    executed do |context|
      context.retrieved_items.each do |item|
        User.create(
          first_name: item[0],
          last_name: item[1],
          email: item[2],
          phone_number: item[3],
          address: item[4],
          country: item[5]
        )
      end
    end
  end
end
