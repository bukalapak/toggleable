require 'spec_helper'
require 'active_support/inflector'
require 'pry'

class SampleFeature
  include Toggleable::Base

  DESC = 'description'.freeze
end

RSpec.describe Toggleable::Base, :type => :model do
  subject { SampleFeature }

  it { expect(described_class.const_defined? 'DEFAULT_VALUE').to be_truthy }

  it { is_expected.to respond_to(:active?) }
  it { is_expected.to respond_to(:activate!) }
  it { is_expected.to respond_to(:deactivate!) }
  it { is_expected.to respond_to(:key) }
  it { is_expected.to respond_to(:description) }

  it { expect(subject.description).to eq('SampleFeature') }
  it { expect(subject.active?).to be_falsy }
  it { expect(subject.key).to eq(subject.name.underscore) }
  it do
    # add description method to SampleFeature
    SampleFeature.instance_eval do
      def description
        SampleFeature::DESC
      end
    end

    expect(subject.description).to eq('description')
  end

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

    context 'wrong argument type for to bool' do
      let(:wrong_args) { 'wrong args' }

      before do
        allow(subject).to receive(:toggle_active).and_return(wrong_args)
      end

      it { expect { subject.active? }.to raise_error(ArgumentError) }
    end

  end
end
