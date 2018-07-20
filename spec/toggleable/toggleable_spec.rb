require 'spec_helper'
require 'active_support/inflector'

class SampleFeature
  include Toggleable::Base

  DESC = 'description'.freeze
end

redis_instance = Redis.new(host: ENV['HOST'], port: ENV['PORT'])
redis_storage = Toggleable::RedisStore.new(redis_instance)

RSpec.describe Toggleable::Base, :type => :model do
  subject { SampleFeature }

  it { expect(described_class.const_defined? 'DEFAULT_VALUE').to be_truthy }

  it { is_expected.to respond_to(:active?) }
  it { is_expected.to respond_to(:activate!) }
  it { is_expected.to respond_to(:deactivate!) }
  it { is_expected.to respond_to(:key) }
  it { is_expected.to respond_to(:description) }

  before(:each) do
    allow(Toggleable::FeatureToggler.instance).to receive(:toggle_key).and_return(true)
  end

  describe 'active? before key exist should create the key also' do
    context 'with memory store' do
      before do
        allow(subject).to receive(:toggle_active).and_return(nil)
        allow(Toggleable::FeatureToggler.instance).to receive(:get_key).and_return(false)
      end

      it { expect(subject.active?).to be_falsy }
    end
  end

  it { expect(subject.description).to eq('SampleFeature') }
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

  describe 'logic behavior' do
    let(:actor_id) { 1 }

    context 'activation' do
      before do
        allow(Toggleable::FeatureToggler.instance).to receive(:get_key).and_return(true)
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: SampleFeature.key, value: true, actor: actor_id).and_return(true)
        subject.activate!(actor: actor_id)
        expect(subject.active?).to be_truthy
      end
    end

    context 'deactivation' do
      before do
        allow(Toggleable::FeatureToggler.instance).to receive(:get_key).and_return(false)
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: SampleFeature.key, value: false, actor: actor_id).and_return(true)
        subject.deactivate!(actor: actor_id)
        expect(subject.active?).to be_falsy
      end
    end

    context 'deactivation without namespace' do
      before do
        allow(Toggleable::FeatureToggler.instance).to receive(:get_key).and_return(false)
        allow(Toggleable.configuration).to receive(:namespace).and_return(nil)
      end

      it do
        expect(Toggleable.configuration.logger).to receive(:log).with(key: SampleFeature.key, value: false, actor: actor_id).and_return(true)
        subject.deactivate!(actor: actor_id)
        expect(subject.active?).to be_falsy
      end
    end

    context 'processing class when inactive will do nothing' do
      before do
        subject.deactivate!
        allow(Toggleable::FeatureToggler.instance).to receive(:get_key).and_return(false)
      end

      it do
        subject.process do
          subject.activate!
        end
        expect(subject.active?).to be_falsy
      end
    end

    context 'processing class when active' do
      before do
        allow(Toggleable::FeatureToggler.instance).to receive(:get_key).and_return(false)
        subject.activate!
      end

      it do
        subject.process do
          subject.deactivate!
        end
        expect(subject.active?).to be_falsy
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
