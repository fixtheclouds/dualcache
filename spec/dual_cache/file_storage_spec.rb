RSpec.describe DualCache::FileStorage do
  describe '#write' do
    context 'when exeeding size limit' do
      let(:storage) { described_class.new(nil, 512.bytes) }

      it 'should prune first value' do
        storage.write('foo', 'bar')
        storage.write('text', 'obviously exceeding byte limit')

        expect(storage.read('text')).to be_nil
        expect(storage.read('foo')).not_to be_nil
      end
    end
  end
end
