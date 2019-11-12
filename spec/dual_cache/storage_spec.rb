RSpec.shared_examples 'basic_write' do
  before { storage.write('foo', 'bar') }
end

RSpec.describe DualCache::Storage do
  let(:storage) { described_class.new(params) }
  let(:params) { {} }

  describe '#clear' do
    subject { storage.clear }

    before do
      storage.write('foo', 'bar')
      storage.write('baz', 'qux')
    end

    it 'clears written data' do
      expect { subject }.to change { storage.read('foo') }.from('bar').to(nil)
        .and change { storage.read('baz') }.from('qux').to(nil)
    end
  end

  describe '#read' do
    subject { storage.read('foo') }

    it { is_expected.to be_nil }

    context 'after writing to cache' do
      include_examples 'basic_write'

      it { is_expected.to eq('bar') }

      context 'when exceeding max size' do
        let(:storage) { described_class.new(l1_size: 2.bytes) }

        it { is_expected.to eq('bar') }
      end
    end
  end

  describe '#write' do
    before { storage.clear }

    subject { storage.write('foo', 'bar') }

    it "writes 'foo' to 'bar'" do
      expect { subject }.to change { storage.read('foo') }.from(nil).to('bar')
    end

    context 'when exceeding max size' do
      let(:storage) { described_class.new(l1_size: 2.bytes) }

      it "still writes 'foo' to 'bar'" do
        expect { subject }.to change { storage.read('foo') }.from(nil).to('bar')
      end

      it 'but not available at level 1' do
        expect { subject }.not_to(change { storage.send(:read_entry, 'foo', {}) })
      end
    end
  end

  describe '#delete' do
    include_examples 'basic_write'

    subject { storage.delete('foo') }

    it 'deletes the key' do
      expect { subject }.to change { storage.read('foo') }.from('bar').to(nil)
    end

    context 'when key is at level 2' do
      let(:storage) { described_class.new(l1_size: 2.bytes) }

      it 'deletes value as well' do
        expect { subject }.to change { storage.read('foo') }.from('bar').to(nil)
      end
    end
  end

  describe '#prune' do
    subject { storage.prune(256.bytes) }

    let(:storage) { described_class.new(l1_size: 1.kilobyte) }

    before do
      storage.clear
      storage.write('a', 'b')
      storage.write('text', 'obviously exceeding 16 bytes limit')
    end

    it 'leaves first value at level 1' do
      expect { subject }.not_to(change { storage.send(:read_entry, 'a', {}).value })
    end

    it 'removes second value from level 1' do
      expect { subject }.to change { storage.send(:read_entry, 'text', {}) }.to(nil)
    end

    it 'and moves second value to level 2' do
      expect { subject }.not_to(change { storage.read('text') })
    end
  end

  describe '#move' do
    include_examples 'basic_write'

    subject { storage.move('foo') }

    it 'removes value from level 1' do
      expect { subject }.to change { storage.send(:read_entry, 'foo', {}) }.to(nil)
    end

    it 'moves value to level 2' do
      expect { subject }.to change { storage.level2.read('foo') }.to('bar')
    end
  end
end
