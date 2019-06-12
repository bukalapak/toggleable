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
            'inactive_key' => 'false'          }
        }

        before do
          allow(subject).to receive(:keys).and_return(keys)
          allow(subject).to receive(:features).and_return(['active_key', 'inactive_key'])
        end

        it { expect(subject.available_features).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' }) }
      end

      context 'without memoize with given namespace' do
        let(:keys) {
          {
            'active_key' => 'true',
            'inactive_key' => 'false'          }
        }

        let(:namespace) { "features_1" }
        let(:other_namespace) { "features_2" }

        before do
          Toggleable.configuration.storage.mass_set(keys, namespace: namespace)
          allow(subject).to receive(:features).and_return(['active_key', 'inactive_key'])
        end

        it { expect(subject.available_features(namespace: namespace)).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' }) }
        it { expect(subject.available_features(namespace: other_namespace)).to eq({}) }
      end

      context 'with memoize' do
        let(:keys) {
          {
            'active_key' => 'true',
            'inactive_key' => 'false'          }
        }

        let(:updated_keys) {
          {
            'active_key' => 'false',
            'inactive_key' => 'true'
          }
        }

        before do
          Toggleable.configuration.storage.mass_set(keys, namespace: Toggleable.configuration.namespace)
          allow(subject).to receive(:features).and_return(['active_key', 'inactive_key'])
        end

        it do
          expect(subject.available_features(memoize: true)).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' })
          Toggleable.configuration.storage.mass_set(updated_keys, namespace: Toggleable.configuration.namespace)
          expect(subject.available_features(memoize: true)).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' })
        end
      end

      context 'with memoize with given namespace' do
        let(:keys) {
          {
            'active_key' => 'true',
            'inactive_key' => 'false'          }
        }

        let(:updated_keys) {
          {
            'active_key' => 'false',
            'inactive_key' => 'true'
          }
        }

        let(:namespace) { "features_1" }
        let(:other_namespace) { "features_2" }

        before do
          Toggleable.configuration.storage.mass_set(keys, namespace: namespace)
          allow(subject).to receive(:features).and_return(['active_key', 'inactive_key'])
        end

        it do
          expect(subject.available_features(memoize: true, namespace: namespace)).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' })
          Toggleable.configuration.storage.mass_set(updated_keys, namespace: namespace)
          expect(subject.available_features(memoize: true, namespace: namespace)).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' })
          expect(subject.available_features(memoize: true, namespace: other_namespace)).to eq({})
        end
      end
    end

    describe '#mass_toggle! with memory store' do
      let(:mapping_after) {
        {
          'other_key' => 'true'
        }
      }

      let(:actor_id) { 1 }
      let(:default_namespace) { Toggleable.configuration.namespace }
      let(:namespace) { "features_1" }
      let(:other_namespace) { "features_2" }

      context 'with default namespace' do
        before do
          subject.register('key')
          subject.register('other_key')
        end

        it do
          expect(Toggleable.configuration.logger).to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id, namespace: default_namespace).and_return(true)
          subject.mass_toggle!(mapping_after, actor: actor_id)
          expect(subject.available_features).to include(mapping_after)
        end
      end

      context 'with given namespace' do
        before do
          subject.register('key')
          subject.register('other_key')
        end

        it do
          expect(Toggleable.configuration.logger).not_to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id, namespace: default_namespace)
          expect(Toggleable.configuration.logger).to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id, namespace: namespace).and_return(true)
          subject.mass_toggle!(mapping_after, actor: actor_id, namespace: namespace)
          expect(subject.available_features(namespace: namespace)).to include(mapping_after)
          expect(subject.available_features(namespace: other_namespace)).not_to include(mapping_after)
        end
      end
    end

    describe '#mass_toggle! with redis' do
      before do
        allow(Toggleable.configuration).to receive(:storage).and_return(redis_storage)
        redis_instance.del(Toggleable.configuration.namespace)
      end

      let(:mapping_after) {
        {
          'logged_key' => 'true'        }
      }

      let(:actor_id) { 1 }
      let(:default_namespace) { Toggleable.configuration.namespace }
      let(:other_namespace) { "features_1" }

      context 'with default namespace' do
        before do
          subject.register('logged_key')
        end

        it do
          expect(Toggleable.configuration.logger).to receive(:log).with(key: 'logged_key', value: 'true', actor: actor_id, namespace: default_namespace).and_return(true)
          subject.mass_toggle!(mapping_after, actor: actor_id)
          expect(subject.available_features).to include(mapping_after)
        end
      end

      context 'with given namespace' do
        before do
          redis_instance.del(default_namespace)
          redis_instance.del(other_namespace)
          subject.register('logged_key')
        end

        it do
          expect(Toggleable.configuration.logger).to receive(:log).with(key: 'logged_key', value: 'true', actor: actor_id, namespace: other_namespace).and_return(true)
          expect(Toggleable.configuration.logger).not_to receive(:log).with(key: 'logged_key', value: 'true', actor: actor_id, namespace: default_namespace)

          subject.mass_toggle!(mapping_after, actor: actor_id, namespace: other_namespace)
          expect(subject.available_features(namespace: other_namespace)).to include(mapping_after)
          expect(subject.available_features(namespace: default_namespace)).not_to include(mapping_after)
        end
      end
    end

    describe '#feature toggler get/toggle key' do
      let(:key) { 'test/get_key'}
      let(:actor_id) { 1 }
      let(:other_namespace) { 'features_1' }

      context 'without memoization' do
        it do
          expect(subject.get_key(key)).to be_falsy
          subject.toggle_key(key, true, actor_id)
          expect(subject.get_key(key)).to be_truthy
        end
      end

      context 'without memoization with given namespace' do
        before do
          subject.toggle_key(key, false, actor_id)
        end

        it do
          expect(subject.get_key(key)).to be_falsy
          expect(subject.get_key(key, namespace: other_namespace)).to be_falsy
          subject.toggle_key(key, true, actor_id, namespace: other_namespace)
          expect(subject.get_key(key)).to be_falsy
          expect(subject.get_key(key, namespace: other_namespace)).to be_truthy
        end
      end

      context 'with memoization' do
        before do
          allow(Toggleable.configuration).to receive(:use_memoization).and_return(true)
        end

        it do
          expect(subject.get_key(key)).to be_falsy
          subject.toggle_key(key, true, actor_id)
          expect(subject.get_key(key)).to be_falsy
        end
      end

      context 'with memoization with given namespace' do
        before do
          allow(Toggleable.configuration).to receive(:use_memoization).and_return(true)
        end

        it do
          expect(subject.get_key(key, namespace: other_namespace)).to be_truthy
          subject.toggle_key(key, false, actor_id, namespace: other_namespace)
          expect(subject.get_key(key, namespace: other_namespace)).to be_truthy
        end
      end

      context 'raise error' do
        before do
          allow(Toggleable.configuration.storage).to receive(:get).and_raise(Redis::CannotConnectError)
        end

        it do
          expect(subject.get_key(key)).to be_falsy
        end
      end
    end
  end
end
