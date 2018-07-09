RSpec.describe Toggleable::StorageAbstract, :type => :model do
  let(:storage)  { described_class.new }
  let(:mappings) { { key: true } }

  context 'raise error when not implemented' do
    it { expect { storage.get('key') }.to raise_exception(NotImplementedError) }
    it { expect { storage.get_all }.to raise_exception(NotImplementedError) }
    it { expect { storage.set('key', true) }.to raise_exception(NotImplementedError) }
    it { expect { storage.set_if_not_exist('key', true) }.to raise_exception(NotImplementedError) }
    it { expect { storage.mass_set(mappings) }.to raise_exception(NotImplementedError) }
  end
end
