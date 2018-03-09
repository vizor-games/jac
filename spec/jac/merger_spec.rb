require_relative lib('jac/merger')
require_relative lib('jac/value')

describe Configuration::Merger do
  let(:merger) { Configuration::Merger.new }

  describe '#merge', nested: true do
    it 'merges hashes recursievly' do
      a = Values.of(foo: { qoo: 2 })
      b = Values.of(foo: { bar: 3 })
      c = { foo: { bar: 3, qoo: 2 } }
      expect(merger.merge(a, b)._value).to eq(c)
    end

    it 'merges deep hashes' do
      a = Values.of(nested(2, a: 1, b: 2))
      b = Values.of(nested(2, a: 1, b: 3))
      c = nested(2, a: 1, b: 3)
      expect(merger.merge(a, b)._value).to eq(c)
    end

    it 'does not enter into arrays' do
      a = Values.of(a: [{ b: 3 }])
      b = Values.of(a: [{ b: 4 }])
      expect(merger.merge(a, b)._value).to eq(b._value)
    end

    it 'merges sets' do
      a = Values.of(a: Set.new(1..3))
      b = Values.of(a: Set.new(4..6))
      c = Values.of(a: Set.new(1..6))
      expect(merger.merge(a, b)._value).to eq(c._value)
    end

    context 'when one value is nil but other is set' do
      it 'returns set' do
        a = Values.of(a: nil)
        b = Values.of(a: Set.new(1..3))
        expect(merger.merge(a, b)._value).to eq(b._value)
        expect(merger.merge(b, a)._value).to eq(b._value)
      end
    end
  end
end
