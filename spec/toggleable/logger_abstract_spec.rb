RSpec.describe Toggleable::LoggerAbstract, :type => :model do
  let(:logger)   { described_class.new }
  let(:actor_id) { 1 }

  context 'raise error when not implemented' do
    it { expect { logger.log(_key: 'key', _value: true, _actor: actor_id, _namespace: 'toggleable') }.to raise_exception(NotImplementedError) }
  end
end
