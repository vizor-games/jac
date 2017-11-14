require_relative lib('jac/parser')

describe Jac::Parser::VisitorToRuby do
  context 'when having !set tag' do
    let(:config) do
      <<-YML.strip_indent
      foo: !set
        ? a
        ? b
        ? c
      YML
    end

    let(:stream) do
      YAML.parse_stream(config)
    end

    let(:visitor) do
      Jac::Parser::VisitorToRuby.create
    end

    it 'parses as ruby Set' do
      expect(visitor.accept(stream))
        .to eq([{ 'foo' => Set.new(%w[a b c]) }])
    end
  end
end
