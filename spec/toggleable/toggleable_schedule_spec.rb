require 'spec_helper'
require 'toggleable'
require 'active_support/inflector'
# require 'pry'
require 'erb'

class ToggleableScheduleXample
  include Toggleable::Base
  include Toggleable::Schedule
  def self.description
    'description'
  end
end

RSpec.describe Toggleable::Schedule, type: :model do
  let(:klass) { ToggleableScheduleXample }

  describe '.active?' do
    subject { klass.active? }
    before { allow(klass).to receive(:schedule_active?).and_return(true) }
    it { expect(subject).to be_truthy }
  end

  it { expect(klass).to respond_to(:schedule_active?) }
  it { expect(klass).to respond_to(:schedule_deactivate!) }
  it { expect(klass).to respond_to(:schedule_duration) }
  it { expect(klass).to respond_to(:schedule_duration=) }

  describe '.schedule_activate!' do
    subject { klass.schedule_activate! }
    it { expect(klass).to receive(:activate!).exactly(1).times; subject }
  end

  describe '.activate!' do
    subject { klass.activate! }
    it { expect(klass).to receive(:schedule_deactivate!).exactly(1).times; subject }
  end

  describe '.deactivate!' do
    subject { klass.deactivate! }
    it { expect(klass).to receive(:schedule_deactivate!).exactly(1).times; subject }
  end
end
