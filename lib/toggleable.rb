# Provides a common interface for toggling features
module Toggleable

  NAMESPACE = FeatureToggler::NAMESPACE
  DEFAULT_VALUE = false
  EXPIRED_INTERVAL = 5.minutes

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      FeatureToggler.instance.register(key)
    end
  end

  module ClassMethods
    def active?
      return toggle_active.to_bool unless toggle_active.nil?

      $redis.hsetnx(NAMESPACE, key, DEFAULT_VALUE)
      DEFAULT_VALUE
    end

    def activate!
      $redis.hset(NAMESPACE, key, true)
    end

    def deactivate!
      $redis.hset(NAMESPACE, key, false)
    end

    def key
      @_key ||= name.snakecase
    end

    def description
      name
    end

    # should we encourage proxy classes, heh heh
    def process
      yield if active?
    end

    private

    def toggle_active
      return @_toggle_active if defined?(@_toggle_active) && !read_expired? && !Rails.env.test?
      @_last_read_at = Time.now.localtime
      @_toggle_active = $redis.hget(NAMESPACE, key)
    end

    def read_expired?
      @_last_read_at < Time.now.localtime - EXPIRED_INTERVAL
    end

    def snakecase
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr('-', '_').
      gsub(/\s/, '_').
      gsub(/__+/, '_').
      downcase
    end

    def minutes
      self*60
    end
  end

end
