require_relative lib('jac/merger')

describe Configuration::Merger do
  let(:merger) { Configuration::Merger.new }

  describe '#merge', nested: true do
    it 'merges hashes recursievly' do
      a = { foo: { qoo: 2 } }
      b = { foo: { bar: 3 } }
      c = { foo: { bar: 3, qoo: 2 } }
      expect(merger.merge(a, b)).to eq(c)
    end

    it 'merges deep hashes' do
      a = nested(2, a: 1, b: 2)
      b = nested(2, a: 1, b: 3)
      c = nested(2, a: 1, b: 3)
      expect(merger.merge(a, b)).to eq(c)
    end

    it 'does not enter into arrays' do
      a = { a: [{ b: 3 }] }
      b = { a: [{ b: 4 }] }
      expect(merger.merge(a, b)).to eq(b)
    end

    it 'merges sets' do
      a = { a: Set.new(1..3) }
      b = { a: Set.new(4..6) }
      c = { a: Set.new(1..6) }
      expect(merger.merge(a, b)).to eq(c)
    end

    context 'when one value is nil but other is set' do
      it 'returns set' do
        a = { a: nil }
        b = { a: Set.new(1..3) }
        expect(merger.merge(a, b)).to eq(b)
        expect(merger.merge(b, a)).to eq(b)
      end
    end
  end
end
