RSpec.describe Toggleable::InstrumentorAbstract, :type => :model do
  let(:instrumentor)   { described_class.new }

  context 'raise error when not implemented' do
    it { expect { instrumentor.latency(0, 'test', 'error') }.to raise_exception(NotImplementedError) }
  end
end
