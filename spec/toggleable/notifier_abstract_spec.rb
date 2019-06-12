RSpec.describe Toggleable::NotifierAbstract, :type => :model do
  let(:notifier)   { described_class.new }
  let(:actor_id) { 1 }

  context 'raise error when not implemented' do
    it { expect { notifier.notify({}, actor_id, 'toggleable') }.to raise_exception(NotImplementedError) }
  end
end
