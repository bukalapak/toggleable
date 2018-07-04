require 'spec_helper'
require 'active_support/inflector'

class SampleFeature
  include Toggleable::Base

  DESC = 'description'.freeze

  def self.description
    DESC
  end
end

RSpec.describe Toggleable::Base, :type => :model do
  subject { SampleFeature }

  it { expect(described_class.const_defined? 'DEFAULT_VALUE').to be_truthy }

  it { is_expected.to respond_to(:active?) }
  it { is_expected.to respond_to(:activate!) }
  it { is_expected.to respond_to(:deactivate!) }
  it { is_expected.to respond_to(:key) }
  it { is_expected.to respond_to(:description) }

  it { expect(subject.key).to eq(subject.name.underscore) }
  it { expect(subject.description).to eq('description') }

  context 'logic behavior' do
    let(:actor_id) { 1 }

    context 'activation' do
      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: SampleFeature.key, value: true, actor: actor_id).and_return(true)
        subject.activate!(actor: actor_id)
        expect(subject.active?).to be true
      end
    end

    context 'deactivation' do
      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: SampleFeature.key, value: false, actor: actor_id).and_return(true)
        subject.deactivate!(actor: actor_id)
        expect(subject.active?).to be false
      end
    end
  end
end
