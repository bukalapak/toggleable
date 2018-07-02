require 'spec_helper'

RSpec.describe Toggleable::FeatureToggler, :type => :model do

  context 'FeatureToggler class' do
    subject { described_class.instance }

    it { is_expected.to respond_to(:register) }
    it { is_expected.to respond_to(:available_features) }
    it { is_expected.to respond_to(:mass_toggle!) }

    describe '#register' do
      before { subject.register('key/name') }
      it { expect(subject.features).to include('key/name') }
    end

    describe '#available_features' do
      let(:keys) {
        {
          'active_key' => 'true',
          'inactive_key' => 'false',
          'unavailable_key' => 'true'
        }
      }

      before do
        allow(subject).to receive(:keys).and_return(keys)
        allow(subject).to receive(:features).and_return(['active_key', 'inactive_key'])
      end

      it { expect(subject.available_features).to eq({ 'active_key' => 'true', 'inactive_key' => 'false' }) }
    end

    describe '#mass_toggle!' do
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
        subject.mass_toggle!(mapping_before, actor: actor_id)
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: 'other_key', value: 'true', actor: actor_id).and_return(true)
        subject.mass_toggle!(mapping_after, actor: actor_id)
        expect(subject.available_features).to include(mapping_after)
      end
    end
  end
end
