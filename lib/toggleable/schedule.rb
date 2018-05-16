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
        $redis_host.get("#{SCHEDULE_ACTIVE}::#{key}") == 'true'
      end

      def schedule_activate!
        if schedule_duration <= 0
          self.activate!
        else
          $redis_host.set("#{SCHEDULE_ACTIVE}::#{key}", 'true', ex: schedule_duration)
        end
      end

      def schedule_deactivate!
        $redis_host.expire("#{SCHEDULE_ACTIVE}::#{key}", 0)
      end

      def schedule_duration
        $redis_host.hget(SCHEDULE_DURATION, key).to_i
      end

      def schedule_duration=(duration)
        $redis_host.hset(SCHEDULE_DURATION, key, duration.to_i)
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
