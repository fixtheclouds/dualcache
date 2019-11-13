RSpec.describe DualCache::FileStorage do
  let(:storage) { described_class.new(size, strategy) }
  let(:size) { 1.megabyte }
  let(:strategy) { 'least_used' }

  describe '#write' do
    context 'when exeeding size limit' do
      let(:size) { 512.bytes }

      it 'should prune first value' do
        storage.write('foo', 'bar')
        storage.write('text', 'obviously exceeding byte limit')

        expect(storage.read('text')).to be_nil
        expect(storage.read('foo')).not_to be_nil
      end
    end
  end

  describe '#keys' do
    subject { storage.keys.map { |key| storage.send(:file_path_key, key) }  }

    before do
      storage.clear
      storage.write('saturn', 100)
      storage.write('mars', 101)
      storage.write('venus', 102)
      storage.read('mars')
    end

    context 'given `least used` strategy' do
      let(:strategy) { 'least_used' }

      it 'lists keys ordered by least recently used' do
        is_expected.to eq(%w(saturn venus mars))
      end
    end

    context 'given `most used` strategy' do
      let(:strategy) { 'most_used' }

      it 'lists keys ordered by most recently used' do
        is_expected.to eq(%w(mars venus saturn))
      end
    end
  end
end
