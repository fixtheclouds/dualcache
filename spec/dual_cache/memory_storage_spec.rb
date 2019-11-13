RSpec.describe DualCache::MemoryStorage do
  let(:storage) { described_class.new(size, strategy) }
  let(:size) { nil }
  let(:strategy) { nil }

  describe '#needs_prune?' do
    subject { storage.needs_prune? }

    before do
      storage.clear
      storage.write('text', 'some long string of text')
    end

    context 'when size limit is exceeded' do
      let(:size) { 100.bytes }

      it { is_expected.to be_truthy }

    end

    context 'when size limit is not exceeded' do
      let(:size) { 1.megabyte }

      it { is_expected.to be_falsey }
    end
  end

  describe '#keys' do
    subject { storage.keys }

    before do
      storage.clear
      storage.write('baz', 100)
      storage.write('qux', 101)
      storage.write('bar', 102)
      storage.write('foo', 103)
      storage.read('bar')
    end

    context 'given `least used` strategy' do
      let(:strategy) { 'least_used' }

      it 'lists keys ordered by least recently used' do
        is_expected.to eq(%w(baz qux foo bar))
      end
    end

    context 'given `most used` strategy' do
      let(:strategy) { 'most_used' }

      it 'lists keys ordered by most recently used' do
        is_expected.to eq(%w(bar foo qux baz))
      end
    end
  end
end
