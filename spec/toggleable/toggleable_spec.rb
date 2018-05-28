require 'spec_helper'
require 'toggleable'
require 'active_support/inflector'
# require 'pry'
require 'erb'

class SampleFeature
  include Toggleable::Base

  DESC = 'description'.freeze

  def self.description
    DESC
  end
end

RSpec.describe Toggleable::Base, :type => :model do
  subject { SampleFeature }

  it { expect(described_class.const_defined? 'NAMESPACE').to be_truthy }

  it { is_expected.to respond_to(:active?) }
  it { is_expected.to respond_to(:activate!) }
  it { is_expected.to respond_to(:deactivate!) }
  it { is_expected.to respond_to(:key) }
  it { is_expected.to respond_to(:description) }

  it { expect(subject.key).to eq(subject.name.underscore) }
  it { expect(subject.description).to eq('description') }

  context 'logic behavior' do

    context 'activation' do
      before { subject.activate! }
      it { expect(subject.active?).to be true }
    end

    context 'deactivation' do
      before { subject.deactivate! }
      it { expect(subject.active?).to be false }
    end
  end
end
