require 'lazy_high_charts/engine'
require 'rails_admin_charts/engine'

module RailsAdminCharts
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def total_records_since(since = 30.days.ago, user)
      #date_created_at = "Date(#{self.table_name}.created_at)"
      #totals, before_count = self.group(date_created_at).count, self.where(date_created_at + ' < ?', since.to_date).count
      # TODO separate MySQL/Postgres approaches using ActiveRecord::Base.connection.adapter_name or check hash key is_a? String/Date
      
	  days_between = (Date.today - since.to_date).to_i
	  
	  totals = Hash.new(0)
	  
	  #user = bindings[:controller]._current_user
	  
	  if user._type == 'Admin'
		days_between.times do |s|
		  totals[(Date.today - s.days).to_date] = self.where(:created_at.gte => Date.today - s.days, :created_at.lt => Date.today - (s - 1).days).count
	    end 
	 elsif user._type == 'Owner'
	    if self.method_defined? :shop_owner_id
		   days_between.times do |s|
		    totals[(Date.today - s.days).to_date] = self.where(:created_at.gte => Date.today - s.days, :created_at.lt => Date.today - (s - 1).days, :shop_owner_id => user.id).count
	       end
		   
		elsif self.method_defined? :owner_id
		   days_between.times do |s|
		    totals[(Date.today - s.days).to_date] = self.where(:created_at.gte => Date.today - s.days, :created_at.lt => Date.today - (s - 1).days, :owner_id => user.id).count
	       end
		   
		end
	 end
	  
	  
	  
	  #puts totals
	 before_count = 0
	  if user._type == 'Admin'
		before_count = self.where(:created_at.lte => Date.today - days_between.days).count
	  elsif user._type == 'Owner'
		if self.method_defined? :shop_owner_id
			before_count = self.where(:created_at.lte => Date.today - days_between.days, :shop_owner_id => user.id).count
		elsif self.method_defined? :owner_id
			before_count = self.where(:created_at.lte => Date.today - days_between.days, :owner_id => user.id).count		
		end
	  end
	  
	  
	  #puts before_count
	  
	  (since.to_date..Date.today).each_with_object([]) { |day, a| a << (a.last || before_count) + (totals[day] || totals[day.to_s] || 0) }
    end

    def delta_records_since(since = 30.days.ago)
      date_created_at = "Date(#{self.table_name}.created_at)"
      deltas = self.group(date_created_at).count

      (since.to_date..Date.today).map { |date| deltas[date] ||  deltas[date.to_s] || 0 }
    end

    def graph_data(since=30.days.ago, user)
      [
          {
              name: model_name.plural,
              pointInterval: 1.day * 1000,
              pointStart: since.to_i * 1000,
              data: self.total_records_since(since, user)
          }
      ]
    end

    def xaxis
      "datetime"
    end

    def label_rotation
      "0"
    end

    def chart_type
      ""
    end
  end
end

#require 'rails_admin/config/actions'
require 'rails_admin_charts/rails_admin/config/actions/charts'
