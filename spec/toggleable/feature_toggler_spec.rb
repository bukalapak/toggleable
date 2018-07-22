require 'spec_helper'

redis_instance = Redis.new(host: ENV['HOST'], port: ENV['PORT'])
redis_storage = Toggleable::RedisStore.new(redis_instance)

RSpec.describe Toggleable::FeatureToggler, :type => :model do

  context 'test using memory storage' do
    subject { described_class.instance }

    it { is_expected.to respond_to(:register) }
    it { is_expected.to respond_to(:available_features) }
    it { is_expected.to respond_to(:mass_toggle!) }

    describe '#register' do
      before { subject.register('key/name') }
      it { expect(subject.features).to include('key/name') }
    end

    describe '#available_features' do
      context 'without memoize' do
        let(:keys) {
          {
            'active_key' => 'true',
            'inactive_key' => 'false',
            'unavailable_key' => 'true'
          }
        }

        before do
          allow(subject).to receive(:features).and_return(['active_key', 'inactive_key'])
          allow(subject).to receive(:keys).and_return(keys)
        end

        it { expect(subject.available_features).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' }) }
      end

      context 'with memoize' do
        let(:keys) {
          {
            'active_key' => 'true',
            'inactive_key' => 'false',
            'unavailable_key' => 'true'
          }
        }

        let(:updated_keys) {
          {
            'active_key' => 'false',
            'inactive_key' => 'true'
          }
        }

        before do
          allow(subject).to receive(:features).and_return(['active_key', 'inactive_key'])
          Toggleable.configuration.storage.mass_set(keys, namespace: Toggleable.configuration.namespace)
        end

        it do
          expect(subject.available_features(memoize: true)).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' })
          Toggleable.configuration.storage.mass_set(updated_keys, namespace: Toggleable.configuration.namespace)
          expect(subject.available_features(memoize: true)).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' })
        end
      end
    end

    before do
      stub_request(:put, "http://localhost:8027/_internal/toggle-features/collections").to_return(status: 200, body: 'success')
    end

    describe '#mass_toggle! with memory store' do
      let(:mapping_before) {
        {
          'key' => 'true',
          'other_key' => 'false'
        }
      }

      let(:mapping_after) {
        {
          'key' => 'true',
          'other_key' => 'true'
        }
      }

      let(:actor_id) { 1 }

      before do
        subject.register('key')
        subject.register('other_key')
        allow(subject).to receive(:available_features).and_return(mapping_before)
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id).and_return(true)
        subject.mass_toggle!(mapping_after, actor: actor_id)
      end
    end

    describe '#mass_toggle! with redis' do
      before do
        allow(Toggleable.configuration).to receive(:storage).and_return(redis_storage)
      end

      let(:mapping_before) {
        {
          'key' => 'true',
          'other_key' => 'false'
        }
      }

      let(:mapping_after) {
        {
          'key' => 'true',
          'other_key' => 'true'
        }
      }

      let(:actor_id) { 1 }

      before do
        subject.register('key')
        subject.register('other_key')
        allow(subject).to receive(:available_features).and_return(mapping_before)
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id).and_return(true)
        subject.mass_toggle!(mapping_after, actor: actor_id)
      end
    end
  end
end
