module Toggleable
  module Schedule
    extend ActiveSupport::Concern

    SCHEDULE_NAMESPACE = ("#{Toggleable::Base::NAMESPACE}::schedules").freeze
    SCHEDULE_ACTIVE = ("#{SCHEDULE_NAMESPACE}::active").freeze
    SCHEDULE_DURATION = ("#{SCHEDULE_NAMESPACE}::duration").freeze

    module ClassMethods
      def active?
        schedule_active? || super
      end

      def schedule_active?
        Toggleable::Configuration.redis.get("#{SCHEDULE_ACTIVE}::#{key}") == 'true'
      end

      def schedule_activate!
        if schedule_duration <= 0
          self.activate!
        else
          Toggleable::Configuration.redis.set("#{SCHEDULE_ACTIVE}::#{key}", 'true', ex: schedule_duration)
        end
      end

      def schedule_deactivate!
        Toggleable::Configuration.redis.expire("#{SCHEDULE_ACTIVE}::#{key}", 0)
      end

      def schedule_duration
        Toggleable::Configuration.redis.hget(SCHEDULE_DURATION, key).to_i
      end

      def schedule_duration=(duration)
        Toggleable::Configuration.redis.hset(SCHEDULE_DURATION, key, duration.to_i)
      end

      def activate!
        self.schedule_deactivate!
        super
      end

      def deactivate!
        self.schedule_deactivate!
        super
      end
    end
  end
end
