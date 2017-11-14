describe Helpers::Nested do
  describe '#nested', nested: true do
    context 'when levels is 0' do
      it 'generates plain hash' do
        expect(nested(0, a: 1, b: 2)).to eq(a: 1, b: 2)
      end
    end

    context 'when levels is > 0' do
      it 'generates nested hash' do
        c = {
          a: { a: { a: 1, b: 2 }, b: { a: 1, b: 2 } },
          b: { a: { a: 1, b: 2 }, b: { a: 1, b: 2 } }
        }
        expect(nested(2, a: 1, b: 2)).to eq(c)
      end
    end
  end
end
