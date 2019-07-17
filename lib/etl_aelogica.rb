require "etl_aelogica/version"
require 'light-service'
require 'csv'
require 'open-uri'

module EtlAelogica
  class Error < StandardError; end

  # Organizer
  class EtlOrganizer
    extend LightService::Organizer

    def self.call(args = {})
      with(args).reduce(actions)
    end

    def self.actions
      [
        RetrievesConnectionUrl,
        PullsUnitGroupsDataSource,
        LoadsUnitsGroupsData,
        LoadsUnitsData
      ]
    end
  end

  #Action
  class RetrievesConnectionUrl
    extend LightService::Action
    promises :base_url

    executed do |context|
      context.base_url = 'https://git.appexpress.io/open-source/etl-starter-app/raw/master/data/json'
    end

  end

  #Action
  class PullsUnitGroupsDataSource
    extend LightService::Action
    promises :unit_groups

    executed do |context|
      buffer = open("#{context.base_url}/unit_groups.json").read
      context.unit_groups = JSON.parse(buffer)['unit_groups']
    end
  end

  #Action

  class LoadsUnitsGroupsData
    extend LightService::Action
    expects :unit_groups

    executed do |context|
      context.unit_groups.each do |unit_group_hash|
        invoiceable_fees = unit_group_hash.delete('invoiceable_fees')
        unit_amenities = unit_group_hash.delete('unit_amenities')
        discount_plans = unit_group_hash.delete('discount_plans')
        channel_rate = unit_group_hash.delete('channel_rate')
        unit_type = unit_group_hash.delete('unit_type')
        unit_group_hash.delete('scheduled_move_out_ids')
        unit_group_hash.delete('channel_rate_ids')

        unit_group = UnitGroup.new(unit_group_hash)
        if channel_rate
          if cr = ChannelRate.find_by_id(channel_rate['id'])
            unit_group.channel_rate_id = cr.id
          else
            unit_group.channel_rate = ChannelRate.new(channel_rate)
          end
        end

        if unit_type
          if ut = UnitType.find_by_id(unit_type['id'])
            unit_group.unit_type_id = ut.id
          else
            unit_group.unit_type = UnitType.new(unit_type) if unit_type
          end
        end

        unit_group.save!
        #Add invoiceable_fees
        invoiceable_fees.each do |invoiceable_fee|
          InvoiceableFee.create(invoiceable_fee)  unless InvoiceableFee.exists?(invoiceable_fee['id'])
        end

        #Add unit_amenties
        unit_amenities.each do |unit_amenity|
          UnitAmenity.create(unit_amenity) unless UnitAmenity.exists?(unit_amenity['id'])
        end

        #Add discount_plans
        discount_plans.each do |discount_plan|
          next if DiscountPlan.exists?(discount_plan['id'])
          discount_plan_discounts = discount_plan.delete('discount_plan_discounts')
          discount_plan_controls = discount_plan.delete('discount_plan_controls')
          client_applications = discount_plan.delete('client_applications')
          discount_plan.delete('api_association_ids')
          discount_plan.delete('facility_ids')

          new_discount_plan = DiscountPlan.new(discount_plan)
          new_discount_plan.save!

          discount_plan_discounts.map {|dp| DiscountPlanDiscount.create(dp) unless DiscountPlanDiscount.exists?(dp['id']) }
          discount_plan_controls.each do |dpc|
            dpc.delete('unit_amenity_ids')
            dpc.delete('discount_plan_ids')
            DiscountPlanControl.create(dpc) unless DiscountPlanControl.exists?(dpc['id'])
          end
          client_applications.map {|ca| ClientApplication.create(ca) unless  ClientApplication.exists?(ca['id'])}
        end
      end
    end
  end

  class LoadsUnitsData
    extend LightService::Action

    executed do |context|
      unit_groups = UnitGroup.pluck(:id)
      unit_groups.each do |unit_group|
        buffer = open("#{context.base_url}/#{unit_group}_units.json").read
        units = JSON.parse(buffer)['units']

        units.each do |unit|
          unit.delete('channel_rate')
          unit.delete('unit_amenities')
          Unit.create(unit)
        end
      end

      units_remote = open('https://git.appexpress.io/open-source/etl-starter-app/raw/master/data/csv/units.csv')
      units_csv = CSV.parse(units_remote, headers: true)
      units_csv.each do |row|
        unit = row.to_hash
        unit.delete('channel_rate')
        unit.delete('unit_amenities')
        unit.delete('unit_type')
        new_unit = Unit.new(unit)
        new_unit.save!
      end

    end
  end


end
