require 'spec_helper'

redis_instance = Redis.new(host: ENV['HOST'], port: ENV['PORT'])
redis_storage = Toggleable::RedisStore.new(redis_instance)

RSpec.describe Toggleable::FeatureToggler, :type => :model do

  context 'palanca enabled' do
    subject { described_class.instance }

    it { is_expected.to respond_to(:register) }
    it { is_expected.to respond_to(:available_features) }
    it { is_expected.to respond_to(:mass_toggle!) }

    describe '#register' do
      before { subject.register('key/name') }
      it { expect(subject.features).to include('key/name') }
    end

    describe '#available_features' do
      let(:data) { [{ 'feature' => 'active_key', 'status' => 'true' }, { 'feature' => 'inactive_key', 'status' => 'false' }] }
      let(:response) { { data: data }.to_json }

      before do
        stub_request(:get, "http://localhost:8027/_internal/toggle-features/collections").to_return(status: 200, body: response)
      end

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
        let(:data) { [{ 'feature' => 'active_key', 'status' => 'true' }, { 'feature' => 'inactive_key', 'status' => 'true' }] }

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

    describe 'get key' do
      let(:key) { 'sample_key' }
      let(:data) { { status: true } }
      let(:response) { { data: data }.to_json }

      context 'successful' do
        before do
          stub_request(:get, "http://localhost:8027/_internal/toggle-features?feature=#{key}")
                      .to_return(status: 200, body: response)
        end

        it { expect(subject.get_key(key)).to be_truthy }
      end

      context 'successful with user_id' do
        let(:user_id) { 1 }

        before do
          stub_request(:get, "http://localhost:8027/_internal/toggle-features?feature=#{key}&user_id=#{user_id}")
                      .to_return(status: 200, body: response)
        end

        it { expect(subject.get_key(key, user_id)).to be_truthy }
      end
    end

    before do
      stub_request(:post, "http://localhost:8027/_internal/toggle-features/bulk-update").to_return(status: 200, body: 'success')
    end

    describe '#mass_toggle!' do
      let(:mapping_after) {
        {
          'other_key' => 'true'
        }
      }

      let(:actor_id)    { 1 }
      let(:actor_email) { 'admin@toggle.com' }

      before do
        subject.register('key')
        subject.register('other_key')
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id).and_return(true)
        subject.mass_toggle!(mapping_after, actor: actor_id, email: actor_email)
      end
    end
  end

  context 'palanca disabled' do
    subject { described_class.instance }
    it { is_expected.to respond_to(:register) }
    it { is_expected.to respond_to(:available_features) }
    it { is_expected.to respond_to(:mass_toggle!) }

    before do
      allow(Toggleable.configuration).to receive(:enable_palanca).and_return(false)
    end

    describe '#register' do
      before { subject.register('key/name') }
      it { expect(subject.features).to include('key/name') }
    end

    describe '#available_features' do
      let(:data) { [{ 'feature' => 'active_key', 'status' => 'true' }, { 'feature' => 'inactive_key', 'status' => 'false' }] }
      let(:response) { { data: data }.to_json }

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
          allow(Toggleable.configuration.storage).to receive(:get_all).and_return(keys)
        end

        it { expect(subject.available_features).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' }) }
      end

      context 'with memoize' do
        let(:data) { [{ 'feature' => 'active_key', 'status' => 'true' }, { 'feature' => 'inactive_key', 'status' => 'true' }] }

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

    describe '#mass_toggle! with memory store' do
      let(:mapping_after) {
        {
          'other_key' => 'true'
        }
      }

      let(:actor_id)    { 1 }
      let(:actor_email) { 'admin@toggle.com' }

      before do
        subject.register('key')
        subject.register('other_key')
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id).and_return(true)
        subject.mass_toggle!(mapping_after, actor: actor_id, email: actor_email)
      end
    end

    describe '#mass_toggle! with redis' do
      before do
        allow(Toggleable.configuration).to receive(:storage).and_return(redis_storage)
      end

      let(:mapping_after) {
        {
          'other_key' => 'true'
        }
      }

      let(:actor_id)    { 1 }
      let(:actor_email) { 'admin@toggle.com' }

      before do
        subject.register('key')
        subject.register('other_key')
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id).and_return(true)
        subject.mass_toggle!(mapping_after, actor: actor_id, email: actor_email)
      end
    end
  end
end
